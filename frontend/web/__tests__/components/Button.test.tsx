import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from '@/components/ui/button'

describe('Button Component', () => {
  it('renders button with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument()
  })

  it('handles click events', async () => {
    const handleClick = jest.fn()
    const user = userEvent.setup()
    
    render(<Button onClick={handleClick}>Click me</Button>)
    
    const button = screen.getByRole('button', { name: /click me/i })
    await user.click(button)
    
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('applies disabled state correctly', () => {
    render(<Button disabled>Disabled Button</Button>)
    
    const button = screen.getByRole('button', { name: /disabled button/i })
    expect(button).toBeDisabled()
  })

  it('applies custom className', () => {
    render(<Button className="custom-class">Custom Button</Button>)
    
    const button = screen.getByRole('button', { name: /custom button/i })
    expect(button).toHaveClass('custom-class')
  })

  it('renders with different variants', () => {
    const { rerender } = render(<Button variant="default">Default</Button>)
    expect(screen.getByRole('button', { name: /default/i })).toBeInTheDocument()
    
    rerender(<Button variant="destructive">Destructive</Button>)
    expect(screen.getByRole('button', { name: /destructive/i })).toBeInTheDocument()
    
    rerender(<Button variant="outline">Outline</Button>)
    expect(screen.getByRole('button', { name: /outline/i })).toBeInTheDocument()
    
    rerender(<Button variant="secondary">Secondary</Button>)
    expect(screen.getByRole('button', { name: /secondary/i })).toBeInTheDocument()
    
    rerender(<Button variant="ghost">Ghost</Button>)
    expect(screen.getByRole('button', { name: /ghost/i })).toBeInTheDocument()
    
    rerender(<Button variant="link">Link</Button>)
    expect(screen.getByRole('button', { name: /link/i })).toBeInTheDocument()
  })

  it('renders with different sizes', () => {
    const { rerender } = render(<Button size="default">Default Size</Button>)
    expect(screen.getByRole('button', { name: /default size/i })).toBeInTheDocument()
    
    rerender(<Button size="sm">Small</Button>)
    expect(screen.getByRole('button', { name: /small/i })).toBeInTheDocument()
    
    rerender(<Button size="lg">Large</Button>)
    expect(screen.getByRole('button', { name: /large/i })).toBeInTheDocument()
    
    rerender(<Button size="icon">Icon</Button>)
    expect(screen.getByRole('button', { name: /icon/i })).toBeInTheDocument()
  })
})
