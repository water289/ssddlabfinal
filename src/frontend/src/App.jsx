import React, { useEffect, useState } from 'react'
import Register from './components/Register'
import Login from './components/Login'
import Vote from './components/Vote'
import ElectionBoard from './components/ElectionBoard'
import api, { setAuthToken } from './api'
import './styles.css'

export default function App() {
  const [token, setToken] = useState(localStorage.getItem('token') || '')
  const [user, setUser] = useState(null)
  const [elections, setElections] = useState([])
  const [status, setStatus] = useState('')
  const [results, setResults] = useState(null)

  useEffect(() => {
    setAuthToken(token)
    if (!token) {
      setUser(null)
      return
    }
    api.get('/users/me')
      .then((res) => setUser(res.data))
      .catch(() => {
        handleLogout()
      })
  }, [token])

  useEffect(() => {
    fetchElections()
  }, [])

  const fetchElections = async () => {
    try {
      const res = await api.get('/elections')
      setElections(res.data)
    } catch (error) {
      setStatus(error.response?.data?.detail || 'Unable to load elections')
    }
  }

  const handleLogin = (jwt) => {
    localStorage.setItem('token', jwt)
    setToken(jwt)
    setStatus('Logged in')
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    setToken('')
    setUser(null)
    setAuthToken('')
    setStatus('Logged out')
  }

  const handleResult = (payload) => {
    setResults(payload)
    setStatus('Results loaded')
  }

  return (
    <div className="app-shell">
      <header className="hero">
        <div>
          <h1>Secure Online Voting</h1>
          <p>Register, authenticate, vote, and audit with end-to-end security.</p>
        </div>
        {user && (
          <div className="hero-actions">
            <span>{`${user.username} • ${user.role}`}</span>
            <button onClick={handleLogout}>Logout</button>
          </div>
        )}
      </header>
      <section className="card">
        <div className="card-grid">
          <div>
            <h2>Authentication</h2>
            <Register onMessage={setStatus} />
            <Login onLogin={handleLogin} onMessage={setStatus} />
          </div>
          <div>
            <h2>Elections</h2>
            <ElectionBoard
              elections={elections}
              refresh={fetchElections}
              onResult={handleResult}
              isAdmin={user?.role === 'admin'}
            />
          </div>
        </div>
        <p className="status-text">{status}</p>
      </section>
      <section className="card">
        <h2>Vote</h2>
        <Vote elections={elections} onMessage={setStatus} />
      </section>
      {results && (
        <section className="card">
          <h2>Election results</h2>
          <p className="status-text">Digest: {results.digest}</p>
          <div className="result-list">
            {Object.entries(results.results).map(([choice, count]) => (
              <div key={choice} className="result-row">
                <span>{choice}</span>
                <strong>{count}</strong>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
