import React, { useState } from 'react'
import api from '../api'

export default function Register({ onMessage }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const submit = async () => {
    try {
      await api.post('/auth/register', { username, password })
      setUsername('')
      setPassword('')
      onMessage?.('Registration successful')
    } catch (error) {
      onMessage?.(error.response?.data?.detail || 'Registration failed')
    }
  }
  return (
    <div className="form-block">
      <input placeholder="username" value={username} onChange={(e) => setUsername(e.target.value)} />
      <input placeholder="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button disabled={!username || !password} onClick={submit}>Create voter</button>
    </div>
  )
}
