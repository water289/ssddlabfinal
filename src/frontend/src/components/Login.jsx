import React, { useState } from 'react'
import api from '../api'

export default function Login({ onLogin, onMessage }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const submit = async () => {
    try {
      const params = new URLSearchParams()
      params.append('username', username)
      params.append('password', password)
      const res = await api.post('/auth/token', params)
      onLogin(res.data.access_token)
      setPassword('')
      setUsername('')
      onMessage?.('Logged in')
    } catch (error) {
      onMessage?.(error.response?.data?.detail || 'Login failed')
    }
  }
  return (
    <div className="form-block">
      <input placeholder="username" value={username} onChange={(e) => setUsername(e.target.value)} />
      <input placeholder="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button disabled={!username || !password} onClick={submit}>Login</button>
    </div>
  )
}
