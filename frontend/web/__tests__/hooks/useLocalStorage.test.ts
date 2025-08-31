import { renderHook, act } from '@testing-library/react'

// Mock hook for testing
const useLocalStorage = <T>(key: string, defaultValue: T): [T, (value: T | ((val: T) => T)) => void] => {
  const [storedValue, setStoredValue] = React.useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : defaultValue
    } catch (error) {
      return defaultValue
    }
  })

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value
      setStoredValue(valueToStore)
      window.localStorage.setItem(key, JSON.stringify(valueToStore))
    } catch (error) {
      console.error(error)
    }
  }

  return [storedValue, setValue]
}

describe('useLocalStorage Hook', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    window.localStorage.clear()
  })

  it('should initialize with default value when no value in localStorage', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 'default-value'))
    
    expect(result.current[0]).toBe('default-value')
  })

  it('should read existing value from localStorage', () => {
    // Set up localStorage
    window.localStorage.setItem('test-key', JSON.stringify('existing-value'))
    
    const { result } = renderHook(() => useLocalStorage('test-key', 'default-value'))
    
    expect(result.current[0]).toBe('existing-value')
  })

  it('should update localStorage when value changes', () => {
    const { result } = renderHook(() => useLocalStorage('test-key', 'default-value'))
    
    act(() => {
      result.current[1]('new-value')
    })
    
    expect(result.current[0]).toBe('new-value')
    expect(JSON.parse(window.localStorage.getItem('test-key')!)).toBe('new-value')
  })

  it('should handle complex objects', () => {
    const defaultObj = { name: 'John', age: 30 }
    const newObj = { name: 'Jane', age: 25 }
    
    const { result } = renderHook(() => useLocalStorage('user', defaultObj))
    
    expect(result.current[0]).toEqual(defaultObj)
    
    act(() => {
      result.current[1](newObj)
    })
    
    expect(result.current[0]).toEqual(newObj)
    expect(JSON.parse(window.localStorage.getItem('user')!)).toEqual(newObj)
  })

  it('should handle arrays', () => {
    const defaultArray = [1, 2, 3]
    const newArray = [4, 5, 6]
    
    const { result } = renderHook(() => useLocalStorage('numbers', defaultArray))
    
    expect(result.current[0]).toEqual(defaultArray)
    
    act(() => {
      result.current[1](newArray)
    })
    
    expect(result.current[0]).toEqual(newArray)
    expect(JSON.parse(window.localStorage.getItem('numbers')!)).toEqual(newArray)
  })

  it('should handle null values', () => {
    const { result } = renderHook(() => useLocalStorage('null-key', null))
    
    expect(result.current[0]).toBeNull()
    
    act(() => {
      result.current[1]('not-null')
    })
    
    expect(result.current[0]).toBe('not-null')
  })

  it('should handle undefined values', () => {
    const { result } = renderHook(() => useLocalStorage('undefined-key', undefined))
    
    expect(result.current[0]).toBeUndefined()
    
    act(() => {
      result.current[1]('defined')
    })
    
    expect(result.current[0]).toBe('defined')
  })

  it('should handle function updates', () => {
    const { result } = renderHook(() => useLocalStorage('counter', 0))
    
    act(() => {
      result.current[1]((prev: number) => prev + 1)
    })
    
    expect(result.current[0]).toBe(1)
    expect(JSON.parse(window.localStorage.getItem('counter')!)).toBe(1)
  })

  it('should handle multiple instances with different keys', () => {
    const { result: result1 } = renderHook(() => useLocalStorage('key1', 'value1'))
    const { result: result2 } = renderHook(() => useLocalStorage('key2', 'value2'))
    
    expect(result1.current[0]).toBe('value1')
    expect(result2.current[0]).toBe('value2')
    
    act(() => {
      result1.current[1]('new-value1')
      result2.current[1]('new-value2')
    })
    
    expect(result1.current[0]).toBe('new-value1')
    expect(result2.current[0]).toBe('new-value2')
    expect(JSON.parse(window.localStorage.getItem('key1')!)).toBe('new-value1')
    expect(JSON.parse(window.localStorage.getItem('key2')!)).toBe('new-value2')
  })
})
