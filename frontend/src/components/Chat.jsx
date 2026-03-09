import React, { useState, useEffect, useRef } from 'react'
import { io } from 'socket.io-client'
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
  Divider
} from '@mui/material'

const socket = io('http://localhost:5000')

function Chat() {
  const [messages, setMessages] = useState([])
  const [message, setMessage] = useState('')
  const [roomId, setRoomId] = useState('general')
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
                <ListItem key={index}>
                  <ListItemText
                    primary={msg.message}
                    secondary={`${msg.sender} - ${new Date(msg.timestamp || msg.created_at).toLocaleTimeString()}`}
                  />
                </ListItem>
              ))}
            </List>
            <div ref={messagesEndRef} />
          </Box>

          <Divider />

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