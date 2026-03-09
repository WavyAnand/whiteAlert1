import React, { useState, useEffect, useRef } from 'react'
import { io } from 'socket.io-client'
import axios from 'axios'
import {
  Container,
  Paper,
  TextField,
  Button,
  Typography,
  Box,
  List,
  ListItem,
  ListItemText,
  Divider,
  Modal
} from '@mui/material'

const socket = io('http://localhost:5000')

function Chat() {
  const [messages, setMessages] = useState([])
  const [message, setMessage] = useState('')
  const [roomId, setRoomId] = useState('general')
  const [ticketModalOpen, setTicketModalOpen] = useState(false)
  const [ticketInfo, setTicketInfo] = useState({ message: '', title: '', description: '' })
  const messagesEndRef = useRef(null)

  const user = JSON.parse(localStorage.getItem('user') || '{}')

  useEffect(() => {
    // Join room
    socket.emit('join-room', roomId)

    // Listen for messages
    socket.on('receive-message', (data) => {
      setMessages(prev => [...prev, data])
    })

    return () => {
      socket.off('receive-message')
    }
  }, [roomId])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const sendMessage = (e) => {
    e.preventDefault()
    if (message.trim()) {
      const messageData = {
        roomId,
        message,
        userId: user.id,
        companyId: user.companyId,
        sender: user.email
      }
      socket.emit('send-message', messageData)
      setMessage('')
    }
  }

  const handleCreateTicket = (msg) => {
    setTicketInfo({ message: msg.message, title: msg.message.slice(0,50), description: msg.message })
    setTicketModalOpen(true)
  }

  const submitTicket = async () => {
    try {
      await axios.post('/api/tickets', {
        title: ticketInfo.title,
        description: ticketInfo.description,
        companyId: user.companyId,
        createdBy: user.id
      })
      alert('Ticket created!')
    } catch (err) {
      console.error(err)
      alert('Failed to create ticket')
    }
    setTicketModalOpen(false)
  }

  return (
    <Container maxWidth="md">
      <Box sx={{ mt: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          WhiteAlert Chat
        </Typography>

        <Paper elevation={3} sx={{ height: '70vh', display: 'flex', flexDirection: 'column' }}>
          {/* Messages Area */}
          <Box sx={{ flex: 1, overflow: 'auto', p: 2 }}>
            <List>
              {messages.map((msg, index) => (
                <ListItem key={index} sx={{ flexDirection: 'column', alignItems: 'flex-start' }}>
                  <ListItemText
                    primary={msg.message}
                    secondary={`${msg.sender} - ${new Date(msg.timestamp || msg.created_at).toLocaleTimeString()}`}
                  />
                  <Button
                    size="small"
                    variant="text"
                    onClick={() => handleCreateTicket(msg)}
                    sx={{ mt: 1 }}
                  >
                    Create Ticket
                  </Button>
                </ListItem>
              ))}
            </List>
            <div ref={messagesEndRef} />
          </Box>

          <Divider />

          {/* Ticket Creation Modal */}
          <Modal open={ticketModalOpen} onClose={() => setTicketModalOpen(false)}>
            <Box sx={{
              position: 'absolute',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              bgcolor: 'background.paper',
              boxShadow: 24,
              p: 4,
              width: 400
            }}>
              <Typography variant="h6" component="h2" gutterBottom>
                Create Ticket
              </Typography>
              <TextField
                label="Title"
                fullWidth
                value={ticketInfo.title}
                onChange={(e) => setTicketInfo({ ...ticketInfo, title: e.target.value })}
                sx={{ mb: 2 }}
              />
              <TextField
                label="Description"
                fullWidth
                multiline
                rows={4}
                value={ticketInfo.description}
                onChange={(e) => setTicketInfo({ ...ticketInfo, description: e.target.value })}
                sx={{ mb: 2 }}
              />
              <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                <Button onClick={() => setTicketModalOpen(false)} sx={{ mr: 1 }}>Cancel</Button>
                <Button variant="contained" onClick={submitTicket}>Submit</Button>
              </Box>
            </Box>
          </Modal>

          {/* Input Area */}
          <Box component="form" onSubmit={sendMessage} sx={{ p: 2, display: 'flex' }}>
            <TextField
              fullWidth
              variant="outlined"
              placeholder="Type your message..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              sx={{ mr: 1 }}
            />
            <Button type="submit" variant="contained" disabled={!message.trim()}>
              Send
            </Button>
          </Box>
        </Paper>
      </Box>
    </Container>
  )
}

export default Chat