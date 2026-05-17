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

import { ThemeProvider } from './state/ThemeContext.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <ThemeProvider>
        <AuthProvider>
          <ToastProvider>
            <SiteSettingsProvider>
              <CartProvider>
                <App />
              </CartProvider>
            </SiteSettingsProvider>
          </ToastProvider>
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  </StrictMode>,
)
