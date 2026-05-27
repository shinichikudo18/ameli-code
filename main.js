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
    ocServeProcess = spawn('opencode', ['serve', '--port', String(port)], {
      stdio: ['ignore', 'pipe', 'pipe'],
      cwd: cwd || DEFAULT_PROJECT_DIR,
      shell: true,
    })
    const check = async () => {
      for (let i = 0; i < 15; i++) {
        await new Promise(r => setTimeout(r, 1000))
        const found = await checkServer(port)
        if (found) { resolve(found); return }
      }
      resolve(null)
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
      }
    })
  }

  setTimeout(() => {
    autoUpdater.checkForUpdates()
  }, 5000)

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
