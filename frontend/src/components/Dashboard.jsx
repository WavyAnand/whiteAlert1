import React from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container,
  Paper,
  Typography,
  Box,
  Button,
  Grid,
  Card,
  CardContent
} from '@mui/material'
import ChatIcon from '@mui/icons-material/Chat'
import DashboardIcon from '@mui/icons-material/Dashboard'
import PeopleIcon from '@mui/icons-material/People'

function Dashboard() {
  const navigate = useNavigate()
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    navigate('/login')
  }

  if (!user.id) {
    navigate('/login')
    return null
  }

  return (
    <Container maxWidth="lg">
      <Box sx={{ mt: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
          <Typography variant="h4" component="h1">
            WhiteAlert Dashboard
          </Typography>
          <Button variant="outlined" onClick={handleLogout}>
            Logout
          </Button>
        </Box>

        <Typography variant="h6" gutterBottom>
          Welcome, {user.email}
        </Typography>

        <Grid container spacing={3}>
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <ChatIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Chat</Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Start real-time conversations with your team
                </Typography>
                <Button variant="contained" fullWidth onClick={() => navigate('/chat')}>
                  Open Chat
                </Button>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <DashboardIcon sx={{ mr: 1, color: 'secondary.main' }} />
                  <Typography variant="h6">Tickets</Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Manage support tickets and issues
                </Typography>
                <Button variant="contained" fullWidth onClick={() => navigate('/tickets')}>
                  View Tickets
                </Button>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <PeopleIcon sx={{ mr: 1, color: 'success.main' }} />
                  <Typography variant="h6">Team</Typography>
                </Box>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Manage team members and permissions
                </Typography>
                <Button variant="contained" fullWidth disabled>
                  Coming Soon
                </Button>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        <Box sx={{ mt: 4, p: 3, bgcolor: 'grey.100', borderRadius: 1 }}>
          <Typography variant="h6" gutterBottom>
            MVP Phase 1 Status
          </Typography>
          <Typography variant="body2">
            ✅ Multi-tenant user management<br/>
            ✅ Basic authentication<br/>
            ✅ Real-time chat functionality<br/>
            🚧 Ticket creation from chat (Next Phase)<br/>
            🚧 Role-based dashboards (Next Phase)
          </Typography>
        </Box>
      </Box>
    </Container>
  )
}

export default Dashboard