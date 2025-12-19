import React, { useState } from 'react'
import api from '../api'

export default function ElectionBoard({ elections, refresh, onResult, isAdmin }) {
  const [title, setTitle] = useState('')
  const [status, setStatus] = useState('')

  const createElection = async () => {
    try {
      await api.post('/elections', { title: title.trim() })
      setTitle('')
      setStatus('Election created')
      refresh()
    } catch (error) {
      setStatus(error.response?.data?.detail || 'Unable to create election')
    }
  }

  const closeElection = async (id) => {
    try {
      await api.post(`/elections/${id}/close`)
      setStatus('Election closed')
      refresh()
    } catch (error) {
      setStatus(error.response?.data?.detail || 'Unable to close election')
    }
  }

  const loadResults = async (id) => {
    try {
      const res = await api.get(`/elections/${id}/results`)
      onResult(res.data)
    } catch (error) {
      setStatus(error.response?.data?.detail || 'Unable to fetch results')
    }
  }

  return (
    <div>
      {isAdmin && (
        <div className="form-block">
          <input
            placeholder="New election title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
          <button disabled={!title.trim()} onClick={createElection}>
            Create election
          </button>
        </div>
      )}
      <div className="election-list">
        {elections.length === 0 && <p>No elections found.</p>}
        {elections.map((election) => (
          <div key={election.id} className="election-row">
            <div>
              <strong>{election.title}</strong>
              <div className="muted">{election.is_active ? 'Active' : 'Closed'}</div>
            </div>
            <div>
              {isAdmin && election.is_active && (
                <button onClick={() => closeElection(election.id)}>Close</button>
              )}
              {isAdmin && (
                <button onClick={() => loadResults(election.id)}>Refresh results</button>
              )}
            </div>
          </div>
        ))}
      </div>
      {status && <p className="status-text">{status}</p>}
    </div>
  )
}
