const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
  onServerConnected: (cb) => ipcRenderer.on('server-connected', (_, data) => cb(data)),
  onServerDisconnected: (cb) => ipcRenderer.on('server-disconnected', () => cb()),

  getProviders: () => ipcRenderer.invoke('get-providers'),
  getModels: () => ipcRenderer.invoke('get-models'),
  getDefaultModel: () => ipcRenderer.invoke('get-default-model'),
  listSessions: () => ipcRenderer.invoke('get-sessions'),
  createSession: (opts) => ipcRenderer.invoke('create-session', opts),
  updateSession: (opts) => ipcRenderer.invoke('update-session', opts),
  deleteSession: (opts) => ipcRenderer.invoke('delete-session', opts),
  sendPrompt: (opts) => ipcRenderer.invoke('send-prompt', opts),
  getMessages: (opts) => ipcRenderer.invoke('get-messages', opts),
  getProjects: () => ipcRenderer.invoke('get-projects'),
  getCurrentProject: () => ipcRenderer.invoke('get-current-project'),
  listSkills: () => ipcRenderer.invoke('list-skills'),
  pickDirectory: () => ipcRenderer.invoke('pick-directory'),
  startServerInDir: (opts) => ipcRenderer.invoke('start-server-in-dir', opts),
  renameProject: (opts) => ipcRenderer.invoke('rename-project', opts),
  deleteProject: (opts) => ipcRenderer.invoke('delete-project', opts),

  minimize: () => ipcRenderer.invoke('minimize-window'),
  maximize: () => ipcRenderer.invoke('maximize-window'),
  close: () => ipcRenderer.invoke('close-window'),
})
