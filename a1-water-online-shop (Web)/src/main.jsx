import './polyfills.js'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import App from './App.jsx'
import { CartProvider } from './state/CartContext.jsx'
import { AuthProvider } from './state/AuthContext.jsx'
import { SiteSettingsProvider } from './state/SiteSettingsContext.jsx'
import { ToastProvider } from './state/ToastContext.jsx'
import { NotificationProvider } from './state/NotificationContext.jsx'

import { ThemeProvider } from './state/ThemeContext.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <ThemeProvider>
        <AuthProvider>
          <ToastProvider>
            <NotificationProvider>
              <SiteSettingsProvider>
                <CartProvider>
                  <App />
                </CartProvider>
              </SiteSettingsProvider>
            </NotificationProvider>
          </ToastProvider>
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  </StrictMode>,
)
