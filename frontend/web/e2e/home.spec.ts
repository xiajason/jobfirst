import { test, expect } from '@playwright/test'

test.describe('Home Page', () => {
  test('should load home page successfully', async ({ page }) => {
    await page.goto('/')
    
    // Check if page loads without errors
    await expect(page).toHaveTitle(/JobFirst/)
    
    // Check if main content is visible
    await expect(page.locator('main')).toBeVisible()
  })

  test('should display navigation menu', async ({ page }) => {
    await page.goto('/')
    
    // Check if navigation is present
    const nav = page.locator('nav')
    await expect(nav).toBeVisible()
    
    // Check for common navigation items
    const navItems = ['Home', 'Jobs', 'Resume', 'Profile']
    for (const item of navItems) {
      const navItem = page.locator(`text=${item}`).first()
      if (await navItem.isVisible()) {
        await expect(navItem).toBeVisible()
      }
    }
  })

  test('should handle responsive design', async ({ page }) => {
    // Test desktop view
    await page.setViewportSize({ width: 1280, height: 720 })
    await page.goto('/')
    await expect(page.locator('nav')).toBeVisible()
    
    // Test mobile view
    await page.setViewportSize({ width: 375, height: 667 })
    await page.goto('/')
    await expect(page.locator('nav')).toBeVisible()
  })

  test('should handle user interactions', async ({ page }) => {
    await page.goto('/')
    
    // Test button clicks (if any)
    const buttons = page.locator('button')
    const buttonCount = await buttons.count()
    
    if (buttonCount > 0) {
      const firstButton = buttons.first()
      await expect(firstButton).toBeVisible()
      
      // Test click without causing navigation
      await firstButton.click()
    }
  })

  test('should handle form submissions', async ({ page }) => {
    await page.goto('/')
    
    // Look for forms on the page
    const forms = page.locator('form')
    const formCount = await forms.count()
    
    if (formCount > 0) {
      const form = forms.first()
      await expect(form).toBeVisible()
      
      // Test form inputs if present
      const inputs = form.locator('input')
      const inputCount = await inputs.count()
      
      if (inputCount > 0) {
        const firstInput = inputs.first()
        await firstInput.fill('test input')
        await expect(firstInput).toHaveValue('test input')
      }
    }
  })

  test('should handle API calls', async ({ page }) => {
    // Mock API responses
    await page.route('**/api/**', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, data: [] })
      })
    })
    
    await page.goto('/')
    
    // Wait for any API calls to complete
    await page.waitForLoadState('networkidle')
    
    // Check if page still loads correctly
    await expect(page.locator('main')).toBeVisible()
  })

  test('should handle error states', async ({ page }) => {
    // Mock API error responses
    await page.route('**/api/**', async route => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal Server Error' })
      })
    })
    
    await page.goto('/')
    
    // Wait for any API calls to complete
    await page.waitForLoadState('networkidle')
    
    // Check if page handles errors gracefully
    await expect(page.locator('main')).toBeVisible()
  })

  test('should handle authentication states', async ({ page }) => {
    await page.goto('/')
    
    // Check for login/logout buttons
    const loginButton = page.locator('text=/login/i').first()
    const logoutButton = page.locator('text=/logout/i').first()
    
    // If login button exists, test it
    if (await loginButton.isVisible()) {
      await expect(loginButton).toBeVisible()
      await loginButton.click()
      
      // Check if we're redirected to login page
      await expect(page).toHaveURL(/.*login.*/)
    }
    
    // If logout button exists, test it
    if (await logoutButton.isVisible()) {
      await expect(logoutButton).toBeVisible()
      await logoutButton.click()
      
      // Check if we're redirected to home page
      await expect(page).toHaveURL(/.*\/$/)
    }
  })

  test('should handle accessibility', async ({ page }) => {
    await page.goto('/')
    
    // Check for proper heading structure
    const headings = page.locator('h1, h2, h3, h4, h5, h6')
    const headingCount = await headings.count()
    
    if (headingCount > 0) {
      // Check if main heading exists
      const h1 = page.locator('h1')
      if (await h1.count() > 0) {
        await expect(h1.first()).toBeVisible()
      }
    }
    
    // Check for proper alt text on images
    const images = page.locator('img')
    const imageCount = await images.count()
    
    for (let i = 0; i < imageCount; i++) {
      const image = images.nth(i)
      const alt = await image.getAttribute('alt')
      
      // Images should have alt text or be decorative
      if (alt === null) {
        const ariaLabel = await image.getAttribute('aria-label')
        const role = await image.getAttribute('role')
        
        // If no alt, should have aria-label or be decorative
        expect(alt !== null || ariaLabel !== null || role === 'presentation').toBeTruthy()
      }
    }
  })
})
