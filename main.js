const os = require('os')
const { app, BrowserWindow, ipcMain, Tray, Menu, nativeImage, dialog } = require('electron')
const path = require('path')
const http = require('http')
const { spawn } = require('child_process')
const fs = require('fs')
const fsp = fs.promises
const { autoUpdater } = require('electron-updater')

if (process.env.GH_TOKEN) {
  autoUpdater.token = process.env.GH_TOKEN
} else if (process.env.GITHUB_TOKEN) {
  autoUpdater.token = process.env.GITHUB_TOKEN
}

const gotTheLock = app.requestSingleInstanceLock()
if (!gotTheLock) {
  app.quit()
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore()
      mainWindow.show()
      mainWindow.focus()
    }
  })
}

let mainWindow
let tray
let ocServeProcess = null
let isQuitting = false
const API_BASE = 'http://localhost'
const REPO_ROOT = path.resolve(__dirname)
const CONFIG_PATH = path.join(os.homedir(), '.config', 'ameli-code', 'config.json')
let appConfig = {}
try { appConfig = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8')) } catch {}
const DEFAULT_PROJECT_DIR = appConfig.projectDir || path.join(os.homedir(), 'Opencode')
const USER_NAME = appConfig.userName || os.userInfo().username || 'Franco'

const ICON_PATH = path.join(__dirname, 'assets', 'logo', 'ameli-icon.png')

function apiUrl(port, endpoint) {
  return `${API_BASE}:${port}${endpoint}`
}

function apiFetch(port, endpoint, options = {}) {
  const url = apiUrl(port, endpoint)
  return new Promise((resolve, reject) => {
    const u = new URL(url)
    const opts = {
      hostname: u.hostname,
      port: u.port,
      path: u.pathname + u.search,
      method: options.method || 'GET',
      headers: { 'Content-Type': 'application/json', ...options.headers },
      timeout: 120000,
    }
    const bodyData = options.body ? JSON.stringify(options.body) : null
    if (bodyData) {
      opts.headers['Content-Length'] = Buffer.byteLength(bodyData)
    }
    const req = http.request(opts, (res) => {
      let data = ''
      res.on('data', (chunk) => data += chunk)
      res.on('end', () => {
        try { resolve(JSON.parse(data)) }
        catch { resolve(data) }
      })
    })
    req.on('error', reject)
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')) })
    if (bodyData) req.write(bodyData)
    req.end()
  })
}

function normalizeList(value) {
  if (!value) return []
  return Array.isArray(value) ? value : Object.values(value)
}

function parseSkillMetadata(content) {
  const lines = String(content || '').split(/\r?\n/)
  if (lines[0] !== '---') return { name: '', description: '' }

  let name = ''
  let description = ''
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i]
    if (line === '---') break
    const match = line.match(/^([a-zA-Z0-9_-]+):\s*(.*)$/)
    if (!match) continue
    const key = match[1]
    const value = match[2].trim()
    if (key === 'name') name = value
    if (key === 'description') description = value
  }
  return { name, description }
}

function collectSkillsFromDir(dir, results, seen) {
  if (!dir || !fs.existsSync(dir)) return
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue
    const skillFile = path.join(dir, entry.name, 'SKILL.md')
    if (!fs.existsSync(skillFile)) continue
    const content = fs.readFileSync(skillFile, 'utf8')
    const meta = parseSkillMetadata(content)
    const name = meta.name || entry.name
    if (seen.has(name)) continue
    seen.add(name)
    results.push({
      name,
      description: meta.description || '',
      path: skillFile,
    })
  }
}

function runCommand(command, args, options = {}) {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      cwd: REPO_ROOT,
      shell: false,
      ...options,
    })
    let stdout = ''
    let stderr = ''
    if (child.stdout) child.stdout.on('data', (chunk) => { stdout += chunk })
    if (child.stderr) child.stderr.on('data', (chunk) => { stderr += chunk })
    child.on('error', (error) => resolve({ code: -1, stdout, stderr: error.message }))
    child.on('close', (code) => resolve({ code, stdout, stderr }))
  })
}

async function listAvailableModels(port) {
  const collected = []
  const seen = new Set()

  const addFromProviderPayload = (payload) => {
    const providerList = normalizeList(payload?.providers || payload?.all)
    for (const provider of providerList) {
      const models = normalizeList(provider?.models)
      for (const model of models) {
        const modelID = model?.id || model?.name
        if (!provider?.id || !modelID) continue
        const key = `${provider.id}/${modelID}`
        if (seen.has(key)) continue
        seen.add(key)
        collected.push({
          providerID: provider.id,
          modelID,
          label: `${provider.name || provider.id}: ${model.name || modelID}`,
        })
      }
    }
  }

  try { addFromProviderPayload(await apiFetch(port, '/config/providers')) } catch {}
  try { addFromProviderPayload(await apiFetch(port, '/provider')) } catch {}

  return collected
}

async function getDefaultModel(port) {
  try {
    const cfg = await apiFetch(port, '/config')
    return cfg?.model || ''
  } catch {
    return ''
  }
}

async function listSkills(port) {
  const results = []
  const seen = new Set()
  const home = os.homedir()

  collectSkillsFromDir(path.join(home, '.config', 'opencode', 'skills'), results, seen)
  collectSkillsFromDir(path.join(home, '.claude', 'skills'), results, seen)
  collectSkillsFromDir(path.join(home, '.agents', 'skills'), results, seen)

  try {
    const current = await apiFetch(port, '/project/current')
    const roots = normalizeList(current?.worktree ? [current.worktree] : current?.directory ? [current.directory] : [])
    for (const root of roots) {
      collectSkillsFromDir(path.join(root, '.opencode', 'skills'), results, seen)
      collectSkillsFromDir(path.join(root, '.claude', 'skills'), results, seen)
      collectSkillsFromDir(path.join(root, '.agents', 'skills'), results, seen)
    }
  } catch {}

  return results
}

function createTray() {
  const icon = nativeImage.createFromPath(ICON_PATH)
  const trayIcon = icon.resize({ width: 22, height: 22 })

  tray = new Tray(trayIcon)
  tray.setToolTip('AMELI Code')

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Mostrar ventana',
      click: () => { mainWindow.show(); mainWindow.focus() },
    },
    {
      label: 'Ocultar ventana',
      click: () => mainWindow.hide(),
    },
    { type: 'separator' },
    {
      label: 'Salir',
      click: () => { isQuitting = true; app.quit() },
    },
  ])

  tray.setContextMenu(contextMenu)
  tray.on('click', () => {
    if (mainWindow.isVisible()) mainWindow.hide()
    else { mainWindow.show(); mainWindow.focus() }
  })
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1100,
    height: 750,
    minWidth: 800,
    minHeight: 550,
    frame: false,
    titleBarStyle: 'hidden',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
    backgroundColor: '#1a1a2e',
    title: 'AMELI Code',
    icon: ICON_PATH,
    show: false,
  })

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'))

  mainWindow.once('ready-to-show', () => mainWindow.show())

  mainWindow.on('close', (e) => {
    if (!isQuitting) {
      e.preventDefault()
      mainWindow.hide()
    }
  })
}

autoUpdater.autoDownload = false
autoUpdater.autoInstallOnAppQuit = true

autoUpdater.on('update-available', (info) => {
  const send = (ch, d) => { if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(ch, d) }
  send('update-available', { version: info.version, releaseDate: info.releaseDate })
})

autoUpdater.on('update-not-available', () => {
  const send = (ch, d) => { if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(ch, d) }
  send('update-not-available', true)
})

autoUpdater.on('download-progress', (progress) => {
  const send = (ch, d) => { if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(ch, d) }
  send('update-download-progress', { percent: progress.percent, bytesPerSecond: progress.bytesPerSecond })
})

autoUpdater.on('update-downloaded', (info) => {
  const send = (ch, d) => { if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(ch, d) }
  send('update-downloaded', { version: info.version })
})

autoUpdater.on('error', (err) => {
  const send = (ch, d) => { if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(ch, d) }
  send('update-error', { message: err ? (err.message || String(err)) : 'Error desconocido' })
})

function checkUpdateFallback() {
  const send = (ch, d) => { if (mainWindow && !mainWindow.isDestroyed()) mainWindow.webContents.send(ch, d) }
  const currentVersion = app.getVersion()
  const req = http.get('http://raw.githubusercontent.com/shinichikudo18/ameli-code/main/version.json', (res) => {
    let data = ''
    res.on('data', (chunk) => data += chunk)
    res.on('end', () => {
      try {
        const v = JSON.parse(data)
        if (v.latest && v.latest !== currentVersion) {
          send('update-available', { version: v.latest, releaseDate: '' })
        } else {
          send('update-not-available', true)
        }
      } catch {
        send('update-not-available', true)
      }
    })
  })
  req.on('error', () => {})
  req.setTimeout(8000, () => { req.destroy() })
}

async function checkServer(port) {
  try {
    const res = await apiFetch(port, '/global/health')
    return res && res.healthy ? port : null
  } catch { return null }
}

async function findServer(ports) {
  for (const p of ports) {
    const found = await checkServer(p)
    if (found) return found
  }
  return null
}

function startOpencodeServe(port, cwd) {
  return new Promise((resolve) => {
    let started = false
    ocServeProcess = spawn('opencode', ['serve', '--port', String(port)], {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: cwd || DEFAULT_PROJECT_DIR,
      shell: true,
    })
    ocServeProcess.on('error', (err) => {
      if (!started) {
        started = true
        resolve(null)
      }
    })
    const check = async () => {
      for (let i = 0; i < 15; i++) {
        await new Promise(r => setTimeout(r, 1000))
        const found = await checkServer(port)
        if (found) { started = true; resolve(found); return }
      }
      if (!started) { started = true; resolve(null) }
    }
    check()
  })
}

app.whenReady().then(async () => {
  createTray()
  createWindow()

  const sendToWindow = (channel, data) => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send(channel, data)
    }
  }

  let activePort = null
  const found = await findServer([4096, 4097, 4098, 4099])
  if (found) {
    activePort = found
    sendToWindow('server-connected', { port: activePort })
  } else {
    sendToWindow('server-disconnected')
    startOpencodeServe(4096, DEFAULT_PROJECT_DIR).then((p) => {
      if (p) {
        activePort = p
        sendToWindow('server-connected', { port: p })
      } else {
        runCommand('opencode', ['--version']).then((res) => {
          if (res.code !== 0) {
            sendToWindow('opencode-not-found', true)
          }
        })
      }
    })
  }

  setTimeout(() => {
    autoUpdater.checkForUpdates()
  }, 5000)

  setTimeout(() => {
    checkUpdateFallback()
  }, 15000)

  ipcMain.handle('get-providers', async () => {
    if (!activePort) return null
    try { return await apiFetch(activePort, '/config/providers') } catch {}
    try { return await apiFetch(activePort, '/provider') } catch {}
    return null
  })

  ipcMain.handle('get-models', async () => {
    if (!activePort) return []
    try { return await listAvailableModels(activePort) } catch { return [] }
  })

  ipcMain.handle('get-default-model', async () => {
    if (!activePort) return ''
    try { return await getDefaultModel(activePort) } catch { return '' }
  })

  ipcMain.handle('list-skills', async () => {
    if (!activePort) return []
    try { return await listSkills(activePort) } catch { return [] }
  })

  ipcMain.handle('get-sessions', async () => {
    if (!activePort) return []
    try { return await apiFetch(activePort, '/session') }
    catch { return [] }
  })

  ipcMain.handle('create-session', async (_, { title }) => {
    if (!activePort) return null
    try { return await apiFetch(activePort, '/session', { method: 'POST', body: { title } }) }
    catch { return null }
  })

  ipcMain.handle('update-session', async (_, { sessionId, title }) => {
    if (!activePort) return null
    try { return await apiFetch(activePort, `/session/${sessionId}`, { method: 'PATCH', body: { title } }) }
    catch { return null }
  })

  ipcMain.handle('delete-session', async (_, { sessionId }) => {
    if (!activePort) return false
    try { return await apiFetch(activePort, `/session/${sessionId}`, { method: 'DELETE' }) }
    catch { return false }
  })

  ipcMain.handle('send-prompt', async (_, { sessionId, text, model, agent }) => {
    if (!activePort) return null
    try {
      const body = { parts: [{ type: 'text', text }] }
      if (model) body.model = { providerID: model.split('/')[0], modelID: model.split('/')[1] }
      if (agent) body.agent = agent
      return await apiFetch(activePort, `/session/${sessionId}/message`, { method: 'POST', body })
    } catch (e) { return { error: e.message } }
  })

  ipcMain.handle('get-messages', async (_, { sessionId }) => {
    if (!activePort) return []
    try { return await apiFetch(activePort, `/session/${sessionId}/message`) }
    catch { return [] }
  })

  ipcMain.handle('get-projects', async () => {
    if (!activePort) return []
    try { return await apiFetch(activePort, '/project') }
    catch { return [] }
  })

  ipcMain.handle('get-current-project', async () => {
    if (!activePort) return null
    try { return await apiFetch(activePort, '/project/current') }
    catch { return null }
  })

  ipcMain.handle('pick-directory', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      properties: ['openDirectory'],
      title: 'Seleccionar carpeta del proyecto',
    })
    if (result.canceled || !result.filePaths.length) return null
    return result.filePaths[0]
  })

  ipcMain.handle('start-server-in-dir', async (_, { dir }) => {
    if (ocServeProcess) ocServeProcess.kill()
    ocServeProcess = null
    activePort = null
    const port = 4096
    ocServeProcess = spawn('opencode', ['serve', '--port', String(port)], {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: dir,
      shell: true,
    })
    for (let i = 0; i < 15; i++) {
      await new Promise(r => setTimeout(r, 1000))
      const found = await checkServer(port)
      if (found) {
        activePort = found
        sendToWindow('server-connected', { port: found })
        return { ok: true, port: found }
      }
    }
    return { ok: false }
  })

  ipcMain.handle('rename-project', async (_, { oldPath, newName }) => {
    if (!oldPath || !newName || !newName.trim()) return { ok: false, error: 'Nombre inválido' }
    const parentDir = path.dirname(oldPath)
    const newPath = path.join(parentDir, newName.trim())
    if (fs.existsSync(newPath)) return { ok: false, error: 'Ya existe una carpeta con ese nombre' }
    try {
      await fsp.rename(oldPath, newPath)
      if (lastProjectDir === oldPath) {
        lastProjectDir = newPath
        if (ocServeProcess) ocServeProcess.kill()
        ocServeProcess = null
        activePort = null
        const port = 4096
        ocServeProcess = spawn('opencode', ['serve', '--port', String(port)], {
          stdio: ['ignore', 'pipe', 'pipe'],
          cwd: newPath,
          shell: true,
        })
      }
      return { ok: true, newPath }
    } catch (e) { return { ok: false, error: e.message } }
  })

  ipcMain.handle('delete-project', async (_, { path: projectPath }) => {
    if (!projectPath) return { ok: false, error: 'Ruta inválida' }
    if (projectPath === lastProjectDir) return { ok: false, error: 'No podes borrar el proyecto activo. Cambiá a otro proyecto primero.' }
    const home = os.homedir()
    if (!projectPath.startsWith(home)) return { ok: false, error: 'Solo se pueden borrar proyectos dentro de tu home' }
    try {
      await fsp.rm(projectPath, { recursive: true, force: true })
      return { ok: true }
    } catch (e) { return { ok: false, error: e.message } }
  })

  ipcMain.handle('get-user-name', () => USER_NAME)

  ipcMain.handle('minimize-window', () => mainWindow.minimize())
  ipcMain.handle('maximize-window', () => {
    if (mainWindow.isMaximized()) mainWindow.unmaximize()
    else mainWindow.maximize()
  })
  ipcMain.handle('close-window', () => mainWindow.close())

  ipcMain.handle('check-for-updates', async () => {
    try {
      autoUpdater.checkForUpdates()
      return { ok: true }
    } catch (e) {
      checkUpdateFallback()
      return { ok: false, error: e.message }
    }
  })

  ipcMain.handle('download-update', async () => {
    try {
      autoUpdater.downloadUpdate()
      return { ok: true }
    } catch (e) {
      return { ok: false, error: e.message }
    }
  })

  ipcMain.handle('install-update', () => {
    autoUpdater.quitAndInstall()
  })

  ipcMain.handle('get-app-version', () => app.getVersion())
})

app.on('before-quit', () => { isQuitting = true })

app.on('window-all-closed', () => {
  if (ocServeProcess) ocServeProcess.kill()
  if (process.platform !== 'darwin') app.quit()
})
