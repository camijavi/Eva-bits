import { Routes, Route, Link } from 'react-router-dom'
import Home from './pages/Home'
import NotFound from './pages/NotFound'
import './App.css'

function App() {
  return (
    <div className="app-container">
      <nav>
        <Link to="/">Home</Link>
      </nav>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
    </div>
  )
}

export default App
