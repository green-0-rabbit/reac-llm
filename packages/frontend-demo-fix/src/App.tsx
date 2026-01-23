import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'
import { getEnv } from './lib/env'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
        <a href="https://vitejs.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React + Nginx Envsubst</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
      </div>
      
      <div className="card" style={{ textAlign: 'left', padding: '1rem', background: '#2a2a2a' }}>
        <h2>Runtime Configuration</h2>
        <pre>
API_URL: {getEnv('API_URL') || '(undefined)'}
SESSION_REPLAY_KEY: {getEnv('SESSION_REPLAY_KEY') || '(undefined)'}
PIANO_ANALYTICS_SITE_ID: {getEnv('PIANO_ANALYTICS_SITE_ID') || '(undefined)'}
PIANO_ANALYTICS_COLLECTION_DOMAIN: {getEnv('PIANO_ANALYTICS_COLLECTION_DOMAIN') || '(undefined)'}
        </pre>
      </div>
    </>
  )
}

export default App
