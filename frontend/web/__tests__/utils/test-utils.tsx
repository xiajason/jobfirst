import React, { ReactElement } from 'react'
import { render, RenderOptions } from '@testing-library/react'
import { ThemeProvider } from 'next-themes'

// Mock Next.js router
jest.mock('next/router', () => ({
  useRouter() {
    return {
      route: '/',
      pathname: '/',
      query: {},
      asPath: '/',
      push: jest.fn(),
      pop: jest.fn(),
      reload: jest.fn(),
      back: jest.fn(),
      prefetch: jest.fn().mockResolvedValue(undefined),
      beforePopState: jest.fn(),
      events: {
        on: jest.fn(),
        off: jest.fn(),
        emit: jest.fn(),
      },
      isFallback: false,
    }
  },
}))

// Mock Next.js navigation
jest.mock('next/navigation', () => ({
  useRouter() {
    return {
      push: jest.fn(),
      replace: jest.fn(),
      prefetch: jest.fn(),
      back: jest.fn(),
      forward: jest.fn(),
      refresh: jest.fn(),
    }
  },
  useSearchParams() {
    return new URLSearchParams()
  },
  usePathname() {
    return '/'
  },
}))

// All the providers that your app needs
const AllTheProviders = ({ children }: { children: React.ReactNode }) => {
  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      {children}
    </ThemeProvider>
  )
}

// Custom render function that includes providers
const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options })

// Re-export everything
export * from '@testing-library/react'

// Override render method
export { customRender as render }

// Mock API responses
export const mockApiResponse = (data: any, status = 200) => {
  return Promise.resolve({
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(data),
    text: () => Promise.resolve(JSON.stringify(data)),
  })
}

// Mock fetch
export const mockFetch = (data: any, status = 200) => {
  return jest.fn().mockImplementation(() => mockApiResponse(data, status))
}

// Create test user
export const createTestUser = (overrides = {}) => ({
  id: '1',
  email: 'test@example.com',
  name: 'Test User',
  avatar: 'https://example.com/avatar.jpg',
  ...overrides,
})

// Create test job
export const createTestJob = (overrides = {}) => ({
  id: '1',
  title: 'Software Engineer',
  company: 'Tech Corp',
  location: 'San Francisco, CA',
  salary: '$100,000 - $150,000',
  description: 'We are looking for a talented software engineer...',
  requirements: ['React', 'TypeScript', 'Node.js'],
  ...overrides,
})

// Create test resume
export const createTestResume = (overrides = {}) => ({
  id: '1',
  title: 'Software Engineer Resume',
  summary: 'Experienced software engineer with 5+ years...',
  experience: [
    {
      id: '1',
      title: 'Senior Software Engineer',
      company: 'Tech Corp',
      startDate: '2020-01-01',
      endDate: '2023-01-01',
      description: 'Led development of multiple web applications...',
    },
  ],
  education: [
    {
      id: '1',
      degree: 'Bachelor of Science in Computer Science',
      school: 'University of Technology',
      startDate: '2015-09-01',
      endDate: '2019-05-01',
    },
  ],
  skills: ['React', 'TypeScript', 'Node.js', 'Python'],
  ...overrides,
})

// Wait for element to be visible
export const waitForElement = async (selector: string, timeout = 5000) => {
  const startTime = Date.now()
  
  while (Date.now() - startTime < timeout) {
    const element = document.querySelector(selector)
    if (element && element.offsetParent !== null) {
      return element
    }
    await new Promise(resolve => setTimeout(resolve, 100))
  }
  
  throw new Error(`Element ${selector} not found or not visible within ${timeout}ms`)
}

// Mock localStorage
export const mockLocalStorage = () => {
  const store: { [key: string]: string } = {}
  
  return {
    getItem: jest.fn((key: string) => store[key] || null),
    setItem: jest.fn((key: string, value: string) => {
      store[key] = value
    }),
    removeItem: jest.fn((key: string) => {
      delete store[key]
    }),
    clear: jest.fn(() => {
      Object.keys(store).forEach(key => delete store[key])
    }),
  }
}

// Mock sessionStorage
export const mockSessionStorage = () => {
  const store: { [key: string]: string } = {}
  
  return {
    getItem: jest.fn((key: string) => store[key] || null),
    setItem: jest.fn((key: string, value: string) => {
      store[key] = value
    }),
    removeItem: jest.fn((key: string) => {
      delete store[key]
    }),
    clear: jest.fn(() => {
      Object.keys(store).forEach(key => delete store[key])
    }),
  }
}

// Mock IntersectionObserver
export const mockIntersectionObserver = () => {
  global.IntersectionObserver = class IntersectionObserver {
    constructor() {}
    disconnect() {}
    observe() {}
    unobserve() {}
  }
}

// Mock ResizeObserver
export const mockResizeObserver = () => {
  global.ResizeObserver = class ResizeObserver {
    constructor() {}
    disconnect() {}
    observe() {}
    unobserve() {}
  }
}

// Mock matchMedia
export const mockMatchMedia = () => {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: jest.fn().mockImplementation(query => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    })),
  })
}

// Setup all mocks
export const setupMocks = () => {
  mockIntersectionObserver()
  mockResizeObserver()
  mockMatchMedia()
  
  // Mock fetch
  global.fetch = jest.fn()
  
  // Mock console methods to reduce noise in tests
  const originalError = console.error
  const originalWarn = console.warn
  
  beforeAll(() => {
    console.error = (...args) => {
      if (
        typeof args[0] === 'string' &&
        args[0].includes('Warning: ReactDOM.render is deprecated')
      ) {
        return
      }
      originalError.call(console, ...args)
    }
    
    console.warn = (...args) => {
      if (
        typeof args[0] === 'string' &&
        args[0].includes('Warning:')
      ) {
        return
      }
      originalWarn.call(console, ...args)
    }
  })
  
  afterAll(() => {
    console.error = originalError
    console.warn = originalWarn
  })
}
