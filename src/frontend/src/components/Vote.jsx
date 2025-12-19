import React, { useEffect, useState } from 'react'
import api from '../api'

export default function Vote({ elections, onMessage }) {
  const [electionId, setElectionId] = useState('')
  const [choice, setChoice] = useState('A')
  useEffect(() => {
    if (elections.length > 0) {
      setElectionId(elections[0].id)
    }
  }, [elections])

  const submit = async () => {
    if (!electionId) {
      onMessage?.('Select an election before voting')
      return
    }
    try {
      await api.post('/vote', { election_id: electionId, choice })
      onMessage?.('Vote recorded')
    } catch (error) {
      onMessage?.(error.response?.data?.detail || 'Voting failed')
    }
  }

  return (
    <div className="form-block">
      <label>
        Election
        <select value={electionId} onChange={(e) => setElectionId(Number(e.target.value))}>
          {elections.map((election) => (
            <option key={election.id} value={election.id}>
              {election.title} {election.is_active ? '(active)' : '(closed)'}
            </option>
          ))}
        </select>
      </label>
      <label>
        Choice
        <input value={choice} onChange={(e) => setChoice(e.target.value)} />
      </label>
      <button onClick={submit} disabled={!electionId}>Cast vote</button>
    </div>
  )
}
