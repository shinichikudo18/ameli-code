let currentSessionId = null
let sessions = []
let providers = []

const sessionList = document.getElementById('session-list')
const newSessionForm = document.getElementById('new-session-form')
const sessionTitleInput = document.getElementById('session-title')
const messagesEl = document.getElementById('messages')
const promptInput = document.getElementById('prompt-input')
const chatContainer = document.getElementById('chat-container')
const welcome = document.getElementById('welcome')
const modelSelect = document.getElementById('model-select')
const agentSelect = document.getElementById('agent-select')
const chatTitle = document.getElementById('chat-title')
const skillsModal = document.getElementById('skills-modal')
const skillsList = document.getElementById('skills-list')
const currentProjectEl = document.getElementById('current-project')
const autoStatus = document.getElementById('auto-status')
const sidebar = document.getElementById('sidebar')
const btnToggleSidebar = document.getElementById('btn-toggle-sidebar')
const chatMeta = document.getElementById('chat-meta')
const btnRefreshModels = document.getElementById('btn-refresh-models')
const btnRefreshSkills = document.getElementById('btn-refresh-skills')
const selectedModelBadge = document.getElementById('selected-model-badge')
const skillsActiveCount = document.getElementById('skills-active-count')
let defaultModel = ''
let skillsData = []
let activeSkills = JSON.parse(localStorage.getItem('ameli.activeSkills') || '[]')
if (!activeSkills.includes('ameli-personal')) {
  activeSkills.push('ameli-personal')
  localStorage.setItem('ameli.activeSkills', JSON.stringify(activeSkills))
}
let userName = localStorage.getItem('ameli.userName') || ''
let lastProjectDir = localStorage.getItem('ameli.lastProjectDir') || ''
let lastSessionId = localStorage.getItem('ameli.lastSessionId') || ''
let restoringProject = false
let currentSessionModelKey = ''
let currentProjectPath = ''
let projects = []
let projectList = document.getElementById('project-list')
let renameForm = document.getElementById('rename-project-form')
let renameInput = document.getElementById('rename-project-input')
let renameConfirm = document.getElementById('btn-rename-project-confirm')
let renameCancel = document.getElementById('btn-rename-project-cancel')
let pendingRenamePath = ''
let sessionRenameForm = document.getElementById('rename-session-form')
let sessionRenameInput = document.getElementById('rename-session-input')
let sessionRenameConfirm = document.getElementById('btn-rename-session-confirm')
let sessionRenameCancel = document.getElementById('btn-rename-session-cancel')
let pendingSessionRenameId = ''

renameCancel.onclick = () => {
  renameForm.classList.add('hidden')
  pendingRenamePath = ''
}
renameInput.onkeydown = (e) => {
  if (e.key === 'Enter') { e.preventDefault(); renameConfirm.click() }
  if (e.key === 'Escape') { e.preventDefault(); renameCancel.click() }
}
renameConfirm.onclick = async () => {
  const name = renameInput.value.trim()
  const oldPath = pendingRenamePath
  if (!name || !oldPath) return
  renameForm.classList.add('hidden')
  pendingRenamePath = ''
  const oldName = oldPath.split('/').pop()
  if (name === oldName) return
  const result = await window.electronAPI.renameProject({ oldPath, newName: name })
  if (!result?.ok) { alert(result?.error || 'No se pudo renombrar'); return }
  await loadProjects()
  if (result.newPath === currentProjectPath) {
    currentProjectPath = result.newPath
    lastProjectDir = result.newPath
    localStorage.setItem('ameli.lastProjectDir', result.newPath)
    await loadProject()
  }
}

sessionRenameCancel.onclick = () => {
  sessionRenameForm.classList.add('hidden')
  pendingSessionRenameId = ''
}
sessionRenameInput.onkeydown = (e) => {
  if (e.key === 'Enter') { e.preventDefault(); sessionRenameConfirm.click() }
  if (e.key === 'Escape') { e.preventDefault(); sessionRenameCancel.click() }
}
sessionRenameConfirm.onclick = async () => {
  const title = sessionRenameInput.value.trim()
  const sessionId = pendingSessionRenameId
  if (!title || !sessionId) return
  sessionRenameForm.classList.add('hidden')
  pendingSessionRenameId = ''
  const session = sessions.find(s => s.id === sessionId)
  if (!session || title === (session.title || '')) return
  const updated = await window.electronAPI.updateSession({ sessionId, title })
  if (!updated) {
    alert('No se pudo renombrar la sesion')
    return
  }
  await loadSessions()
  if (currentSessionId === sessionId) {
    chatTitle.textContent = title
  }
}

function $(id) { return document.getElementById(id) }

let sidebarVisible = localStorage.getItem('ameli.sidebarVisible') !== 'false'
document.body.classList.toggle('sidebar-collapsed', !sidebarVisible)
btnToggleSidebar.onclick = () => {
  sidebarVisible = !sidebarVisible
  document.body.classList.toggle('sidebar-collapsed', !sidebarVisible)
  localStorage.setItem('ameli.sidebarVisible', sidebarVisible ? 'true' : 'false')
}

$('btn-new-session').onclick = () => {
  newSessionForm.classList.toggle('hidden')
  if (!newSessionForm.classList.contains('hidden')) sessionTitleInput.focus()
}
$('btn-cancel-session').onclick = () => {
  newSessionForm.classList.add('hidden')
  sessionTitleInput.value = ''
}
$('btn-create-session').onclick = async () => {
  const title = sessionTitleInput.value.trim() || 'Nueva sesion'
  const session = await window.electronAPI.createSession({ title })
  if (session) {
    newSessionForm.classList.add('hidden')
    sessionTitleInput.value = ''
    await loadSessions()
    const nextId = session.id || sessions.find(s => s.title === title)?.id || sessions[0]?.id
    if (nextId) await selectSession(nextId)
  }
}

$('btn-send').onclick = sendPrompt
promptInput.onkeydown = (e) => {
  if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendPrompt() }
}

$('btn-load-skills').onclick = loadSkillsModal
$('btn-close-skills').onclick = () => skillsModal.classList.add('hidden')
btnRefreshModels.onclick = async () => {
  await loadProviders()
}
btnRefreshSkills.onclick = async () => {
  await loadSkillsModal(true)
}

modelSelect.onchange = () => {
  persistSessionModel()
  updateSelectedModelBadge()
}

async function doNewProject() {
  $('btn-new-project').disabled = true
  $('btn-new-project').textContent = 'Seleccionando...'
  $('btn-welcome-new-project').disabled = true
  const dir = await window.electronAPI.pickDirectory()
  if (!dir) {
    $('btn-new-project').disabled = false
    $('btn-new-project').textContent = '+ Nuevo proyecto'
    $('btn-welcome-new-project').disabled = false
    return
  }
  if (autoStatus) autoStatus.textContent = 'Iniciando servidor en ' + dir.split('/').pop()
  const result = await window.electronAPI.startServerInDir({ dir })
  $('btn-new-project').disabled = false
  $('btn-new-project').textContent = '+ Nuevo proyecto'
  $('btn-welcome-new-project').disabled = false
  if (!result || !result.ok) {
    if (autoStatus) autoStatus.textContent = 'Error al iniciar servidor'
  }
}

$('btn-new-project').onclick = doNewProject
$('btn-welcome-new-project').onclick = doNewProject

window.electronAPI.onServerConnected(async ({ port }) => {
  if (restoringProject) return
  welcome.classList.add('hidden')
  chatContainer.classList.remove('hidden')
  document.body.classList.toggle('sidebar-collapsed', !sidebarVisible)
  await bootstrapWorkspace()
  promptInput.focus()
})

window.electronAPI.onServerDisconnected(() => {
  chatContainer.classList.add('hidden')
  welcome.classList.remove('hidden')
  if (autoStatus) autoStatus.textContent = 'Servidor no encontrado. Inicia opencode serve o usa Nuevo proyecto.'
  currentProjectEl.innerHTML = '<span class="project-icon">📁</span><span class="project-name">Sin proyecto</span>'
  chatMeta.textContent = 'Selecciona una sesion'
})

async function autoRestoreLastProject() {
  if (!lastProjectDir || restoringProject) return
  restoringProject = true
  if (autoStatus) autoStatus.textContent = 'Restaurando proyecto anterior...'
  const result = await window.electronAPI.startServerInDir({ dir: lastProjectDir })
  restoringProject = false
  if (!result?.ok && autoStatus) {
    autoStatus.textContent = 'No se pudo restaurar el proyecto anterior.'
  }
}

async function loadProject() {
  const proj = await window.electronAPI.getCurrentProject()
  if (proj) {
    const name = proj.worktree ? proj.worktree.split('/').pop() : 'Proyecto'
    currentProjectEl.innerHTML = `<span class="project-icon">📁</span><span class="project-name">${escapeHtml(name)}</span>`
    lastProjectDir = proj.worktree || proj.directory || lastProjectDir
    currentProjectPath = lastProjectDir
    localStorage.setItem('ameli.lastProjectDir', lastProjectDir)
  }
  return proj
}

async function loadProjects() {
  projects = await window.electronAPI.getProjects() || []
  projectList.innerHTML = ''
  for (const p of projects) {
    const dir = p.worktree || p.directory || ''
    const name = dir ? dir.split('/').pop() : 'Proyecto'
    const isCurrent = dir === currentProjectPath
    const div = document.createElement('div')
    div.className = 'project-item' + (isCurrent ? ' active' : '')
    div.dataset.projectPath = dir
    div.innerHTML = `
      <div class="project-item-row">
        <div class="project-item-main">
          <div class="p-title">${escapeHtml(name)}</div>
          <div class="p-path">${escapeHtml(dir)}</div>
        </div>
        <div class="project-actions">
          <button class="project-action-btn" data-action="rename" type="button" title="Renombrar">✎</button>
          <button class="project-action-btn" data-action="delete" type="button" title="Borrar">🗑</button>
        </div>
      </div>`
    const renameBtn = div.querySelector('[data-action="rename"]')
    const deleteBtn = div.querySelector('[data-action="delete"]')
    renameBtn.onclick = (e) => { e.stopPropagation(); handleProjectAction('rename', dir) }
    deleteBtn.onclick = (e) => { e.stopPropagation(); handleProjectAction('delete', dir) }
    div.onclick = () => switchProject(dir)
    projectList.appendChild(div)
  }
}

async function switchProject(dir) {
  if (!dir || dir === currentProjectPath) return
  const result = await window.electronAPI.startServerInDir({ dir })
  if (!result?.ok) return
  await bootstrapWorkspace()
}

async function handleProjectAction(action, projectPath) {
  if (action === 'rename') {
    const oldName = projectPath.split('/').pop()
    renameInput.value = oldName
    pendingRenamePath = projectPath
    renameForm.classList.remove('hidden')
    renameInput.focus()
    renameInput.select()
    return
  }
  if (action === 'delete') {
    const name = projectPath.split('/').pop()
    const ok = confirm(`Borrar el proyecto "${name}"?\n\nSe borrará toda la carpeta. No se puede deshacer.`)
    if (!ok) return
    const result = await window.electronAPI.deleteProject({ path: projectPath })
    if (!result?.ok) {
      alert(result?.error || 'No se pudo borrar')
      return
    }
    projects = projects.filter(p => (p.worktree || p.directory || '') !== projectPath)
    await loadProjects()
    if (projectPath === currentProjectPath) {
      currentProjectPath = ''
      currentProjectEl.innerHTML = '<span class="project-icon">📁</span><span class="project-name">Sin proyecto</span>'
    }
  }
}

async function loadProviders() {
  modelSelect.innerHTML = '<option value="">Cargando modelos...</option>'
  const [models, defaultModelValue] = await Promise.all([
    window.electronAPI.getModels(),
    window.electronAPI.getDefaultModel(),
  ])
  defaultModel = defaultModelValue || ''

  modelSelect.innerHTML = ''
  if (!models.length) {
    modelSelect.innerHTML = '<option value="">No hay modelos disponibles</option>'
    return
  }

  modelSelect.appendChild(new Option('Elegi modelo', ''))
  for (const model of models) {
    const opt = document.createElement('option')
    opt.value = `${model.providerID}/${model.modelID}`
    opt.textContent = model.label
    opt.title = `Proveedor: ${model.providerID} · Modelo: ${model.modelID}`
    modelSelect.appendChild(opt)
  }

  if (defaultModel) {
    const hasDefault = [...modelSelect.options].some(opt => opt.value === defaultModel)
    if (hasDefault) modelSelect.value = defaultModel
  }
  if (currentSessionId) restoreSessionModel()
  updateSelectedModelBadge()
}

async function loadSessions() {
  sessions = await window.electronAPI.listSessions() || []
  sessionList.innerHTML = ''
  for (const s of sessions) {
    const div = document.createElement('div')
    div.className = 'session-item' + (s.id === currentSessionId ? ' active' : '')
    div.dataset.sessionId = s.id
    div.innerHTML = `
      <div class="session-item-row">
        <div class="session-item-main">
          <div class="s-title">${escapeHtml(s.title || 'Sin titulo')}</div>
          <div class="s-date">${new Date(s.time?.created).toLocaleDateString() || s.id.slice(0, 8)} <span class="badge" title="Session ID">${escapeHtml(s.id.slice(0, 8))}</span></div>
        </div>
        <div class="session-actions">
          <button class="session-action-btn" data-action="rename" type="button" title="Renombrar">✎</button>
          <button class="session-action-btn" data-action="delete" type="button" title="Borrar">🗑</button>
        </div>
      </div>`
    const renameBtn = div.querySelector('[data-action="rename"]')
    const deleteBtn = div.querySelector('[data-action="delete"]')
    renameBtn.onclick = (e) => { e.stopPropagation(); handleSessionAction('rename', s.id) }
    deleteBtn.onclick = (e) => { e.stopPropagation(); handleSessionAction('delete', s.id) }
    div.onclick = () => selectSession(s.id)
    sessionList.appendChild(div)
  }
}

async function selectSession(id) {
  currentSessionId = id
  lastSessionId = id
  localStorage.setItem('ameli.lastSessionId', id)
  currentSessionModelKey = `ameli.sessionModel.${id}`
  document.querySelectorAll('.session-item').forEach(el => {
    el.classList.toggle('active', el.dataset.sessionId === id)
  })

  const session = sessions.find(s => s.id === id)
  chatTitle.textContent = session?.title || 'Sesion'
  chatMeta.textContent = session ? `${session.directory || 'Directorio desconocido'} · ${session.id.slice(0, 8)}` : 'Selecciona una sesion'
  messagesEl.innerHTML = ''
  chatContainer.classList.remove('hidden')
  welcome.classList.add('hidden')

  restoreSessionModel()

  const msgs = await window.electronAPI.getMessages({ sessionId: id })
  for (const msg of msgs || []) {
    addMessage(msg.info.role, extractText(msg.parts))
  }
  messagesEl.scrollTop = messagesEl.scrollHeight
  promptInput.focus()
}

async function handleSessionAction(action, sessionId) {
  const session = sessions.find(s => s.id === sessionId)
  if (!session) return
  if (action === 'rename') {
    sessionRenameInput.value = session.title || ''
    pendingSessionRenameId = sessionId
    sessionRenameForm.classList.remove('hidden')
    sessionRenameInput.focus()
    sessionRenameInput.select()
    return
  }
  if (action === 'delete') {
    const ok = confirm(`Borrar la sesion "${session.title || 'Sin titulo'}"?`)
    if (!ok) return
    const deleted = await window.electronAPI.deleteSession({ sessionId })
    if (deleted) {
      const wasCurrent = currentSessionId === sessionId
      sessions = sessions.filter(s => s.id !== sessionId)
      if (wasCurrent) {
        currentSessionId = null
        chatMeta.textContent = 'Selecciona una sesion'
        messagesEl.innerHTML = ''
        chatContainer.classList.add('hidden')
        welcome.classList.remove('hidden')
      }
      await loadSessions()
      if (wasCurrent && sessions[0]) await selectSession(sessions[0].id)
    }
  }
}

async function sendPrompt() {
  const text = promptInput.value.trim()
  if (!text || !currentSessionId) return

  const model = modelSelect.value || undefined
  const agent = agentSelect.value
  const effectiveText = activeSkills.length
    ? `Skills activas para esta operacion: ${activeSkills.join(', ')}\n\n${text}`
    : text

  addMessage('user', text)
  promptInput.value = ''

  const tempId = 'loading-' + Date.now()
  const loadingDiv = document.createElement('div')
  loadingDiv.className = 'msg assistant'
  loadingDiv.id = tempId
  loadingDiv.innerHTML = '<div class="role-label">AMELI</div><div class="typing"><span></span><span></span><span></span></div>'
  messagesEl.appendChild(loadingDiv)
  messagesEl.scrollTop = messagesEl.scrollHeight

  const result = await window.electronAPI.sendPrompt({ sessionId: currentSessionId, text: effectiveText, model, agent })
  const loadingEl = document.getElementById(tempId)
  if (loadingEl) loadingEl.remove()

  if (result && !result.error) {
    const assistantText = extractText(result.parts)
    addMessage('assistant', assistantText)
  } else if (result?.error) {
    addMessage('system', `Error: ${result.error}`)
  }
  messagesEl.scrollTop = messagesEl.scrollHeight
}

function updateSelectedModelBadge() {
  const value = modelSelect.value
  if (!value) {
    selectedModelBadge.textContent = defaultModel ? `Default: ${defaultModel}` : 'Sin modelo'
    selectedModelBadge.title = defaultModel ? `Modelo por defecto: ${defaultModel}` : 'No hay modelo seleccionado'
    return
  }
  selectedModelBadge.textContent = value
  selectedModelBadge.title = `Modelo seleccionado: ${value}`
}

function persistSessionModel() {
  if (!currentSessionId) return
  localStorage.setItem(currentSessionModelKey, modelSelect.value || '')
}

function restoreSessionModel() {
  if (!currentSessionId) return
  const saved = localStorage.getItem(`ameli.sessionModel.${currentSessionId}`) || ''
  if (saved && [...modelSelect.options].some(opt => opt.value === saved)) {
    modelSelect.value = saved
  } else if (defaultModel && [...modelSelect.options].some(opt => opt.value === defaultModel)) {
    modelSelect.value = defaultModel
  }
  updateSelectedModelBadge()
}

function addMessage(role, text) {
  if (!text) return
  const div = document.createElement('div')
  div.className = `msg ${role}`
  div.setAttribute('data-selectable', 'true')
  const label = role === 'user' ? (userName || 'Usuario') : 'AMELI'
  div.innerHTML = `<div class="role-label">${label}</div>${escapeHtml(text)}`
  messagesEl.appendChild(div)
}

messagesEl.addEventListener('mouseup', () => {
  const selection = window.getSelection()?.toString().trim()
  if (selection) navigator.clipboard?.writeText(selection).catch(() => {})
})

document.addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'c') {
    const selection = window.getSelection()?.toString().trim()
    if (selection) {
      navigator.clipboard?.writeText(selection).catch(() => {})
      e.preventDefault()
    }
  }
})

function extractText(parts) {
  if (!parts) return ''
  return parts.filter(p => p.type === 'text').map(p => p.text).join('\n')
}

async function loadSkillsModal() {
  skillsList.innerHTML = '<p style="color:var(--text-dim)">Cargando skills...</p>'
  skillsModal.classList.remove('hidden')
  try {
    skillsData = await window.electronAPI.listSkills()
    skillsList.innerHTML = ''
    updateSkillsActiveCount()
    if (!skillsData.length) {
      skillsList.innerHTML = '<p style="color:var(--text-dim)">No hay skills disponibles</p>'
      return
    }
    for (const skill of skillsData) {
      const div = document.createElement('div')
      div.className = 'skill-entry'
      div.dataset.skillName = skill.name
      div.classList.toggle('active', activeSkills.includes(skill.name))
      div.title = skill.path || skill.name
      div.innerHTML = `
        <div class="sk-name">${escapeHtml(skill.name)} <span class="badge">skill</span></div>
        <div class="sk-desc">${escapeHtml(skill.description || '')}</div>
        <div class="sk-state">${activeSkills.includes(skill.name) ? 'Activa para esta operacion' : 'Apagada para esta operacion'}</div>
        <button class="skill-toggle ${activeSkills.includes(skill.name) ? 'active' : ''}" type="button">${activeSkills.includes(skill.name) ? 'Desactivar' : 'Activar'}</button>`
      skillsList.appendChild(div)
    }
  } catch {
    skillsList.innerHTML = '<p style="color:var(--text-dim)">No se pudieron cargar los skills</p>'
  }
}

skillsList.addEventListener('click', (e) => {
  const entry = e.target.closest('.skill-entry')
  if (!entry?.dataset.skillName) return
  if (!e.target.closest('.skill-toggle') && !e.target.closest('.skill-entry')) return
  toggleSkill(entry.dataset.skillName)
})

function toggleSkill(name) {
  if (activeSkills.includes(name)) {
    activeSkills = activeSkills.filter(s => s !== name)
  } else {
    activeSkills = [...activeSkills, name]
  }
  localStorage.setItem('ameli.activeSkills', JSON.stringify(activeSkills))
  renderSkills()
}

function renderSkills() {
  if (!skillsData.length) return
  skillsList.innerHTML = ''
  updateSkillsActiveCount()
  for (const skill of skillsData) {
    const active = activeSkills.includes(skill.name)
    const div = document.createElement('div')
    div.className = `skill-entry ${active ? 'active' : ''}`
    div.dataset.skillName = skill.name
    div.title = skill.path || skill.name
    div.innerHTML = `
      <div class="sk-name">${escapeHtml(skill.name)} <span class="badge">skill</span></div>
      <div class="sk-desc">${escapeHtml(skill.description || '')}</div>
      <div class="sk-state">${active ? 'Activa para esta operacion' : 'Apagada para esta operacion'}</div>
      <button class="skill-toggle ${active ? 'active' : ''}" type="button">${active ? 'Desactivar' : 'Activar'}</button>`
    skillsList.appendChild(div)
  }
}

function updateSkillsActiveCount() {
  skillsActiveCount.textContent = `${activeSkills.length} activas`
}

async function restoreLastSession() {
  if (!lastSessionId) return
  const match = sessions.find(s => s.id === lastSessionId)
  if (match) await selectSession(match.id)
}

async function loadUserName() {
  const name = await window.electronAPI.getUserName()
  if (name) {
    userName = name
    localStorage.setItem('ameli.userName', name)
  }
}

async function bootstrapWorkspace() {
  await loadUserName()
  const current = await loadProject()
  const currentPath = current?.worktree || current?.directory || currentProjectPath || ''

  if (lastProjectDir && currentPath !== lastProjectDir) {
    await autoRestoreLastProject()
  }

  await Promise.all([loadProject(), loadProviders(), loadSessions(), loadProjects()])
  await restoreLastSession()
}

bootstrapWorkspace()

window.electronAPI.onOpencodeNotFound(() => {
  const el = document.getElementById('opencode-missing')
  const status = document.getElementById('auto-status')
  if (el) el.classList.remove('hidden')
  if (status) status.classList.add('hidden')
})

document.getElementById('btn-retry-opencode')?.addEventListener('click', () => {
  const el = document.getElementById('opencode-missing')
  const status = document.getElementById('auto-status')
  if (el) el.classList.add('hidden')
  if (status) {
    status.classList.remove('hidden')
    status.textContent = 'Reintentando...'
  }
  window.electronAPI.checkForUpdates()
  location.reload()
})

function escapeHtml(str) {
  if (!str) return ''
  const div = document.createElement('div')
  div.textContent = str
  return div.innerHTML
}

async function initUpdater() {
  const versionEl = document.getElementById('version-text')
  const updateCheckText = document.getElementById('update-check-text')
  const updateBar = document.getElementById('update-bar')
  const updateVersionText = document.getElementById('update-version-text')
  const updateProgressText = document.getElementById('update-progress-text')
  const btnDownload = document.getElementById('btn-update-download')
  const btnInstall = document.getElementById('btn-update-install')
  const btnSkip = document.getElementById('btn-update-skip')

  const version = await window.electronAPI.getAppVersion()
  versionEl.textContent = `v${version}`

  updateCheckText.textContent = 'Buscando actualizaciones...'

  window.electronAPI.onUpdateAvailable((info) => {
    updateCheckText.textContent = ''
    updateBar.classList.remove('hidden')
    updateVersionText.textContent = `Nueva versión: v${info.version}`
    btnDownload.classList.remove('hidden')
    btnInstall.classList.add('hidden')
    updateProgressText.textContent = ''
  })

  window.electronAPI.onUpdateNotAvailable(() => {
    updateCheckText.textContent = 'Actualizado'
  })

  window.electronAPI.onUpdateDownloadProgress((progress) => {
    btnDownload.classList.add('hidden')
    const pct = Math.round(progress.percent)
    updateProgressText.textContent = `Descargando... ${pct}%`
  })

  window.electronAPI.onUpdateDownloaded(() => {
    updateProgressText.textContent = 'Descarga completa'
    btnDownload.classList.add('hidden')
    btnInstall.classList.remove('hidden')
  })

  window.electronAPI.onUpdateError((err) => {
    updateCheckText.textContent = 'No se pudo verificar'
    if (updateBar.classList.contains('hidden')) return
    updateBar.classList.add('hidden')
  })

  btnDownload.addEventListener('click', () => {
    btnDownload.disabled = true
    btnDownload.textContent = 'Descargando...'
    window.electronAPI.downloadUpdate()
  })

  btnInstall.addEventListener('click', () => {
    window.electronAPI.installUpdate()
  })

  btnSkip.addEventListener('click', () => {
    updateBar.classList.add('hidden')
  })

  window.electronAPI.checkForUpdates()
}

initUpdater()
