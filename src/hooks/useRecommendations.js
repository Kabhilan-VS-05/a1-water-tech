import { useMemo } from 'react'
import useProducts from './useProducts.js'
import { useCart } from '../state/CartContext.jsx'

// Simulated Association Rules
const RULES = [
    {
        targetCategory: 'Purifiers',
        recommendCategory: 'Services',
        reason: 'Protect your new purifier with an annual maintenance plan.',
    },
    {
        targetCategory: 'Filters',
        recommendCategory: 'Services',
        reason: 'Need help installing? Book a certified technician for professional setup.',
    },
    {
        targetCategory: 'Commercial',
        recommendCategory: 'Services',
        reason: 'Keep your business running with priority office support.',
    },
]

export default function useRecommendations() {
    const { items: allProducts } = useProducts()
    const { items: cartItems } = useCart()

    const recommendations = useMemo(() => {
        if (!allProducts.length) return { title: '', reason: '', items: [] }

        // 1. Analyze Cart Content
        const cartCategories = new Set(cartItems.map((item) => item.category))

        // 2. Find matching rules
        let activeRule = null
        for (const rule of RULES) {
            if (cartCategories.has(rule.targetCategory)) {
                activeRule = rule
                break
            }
        }

        // Default recommendation if cart is empty or no rule matches
        if (!activeRule) {
            if (cartItems.length === 0) {
                // Cold start: Recommend 'Purifiers'
                return {
                    title: 'Best Sellers for Your Home',
                    reason: 'Top-rated purifiers designed for Tamil Nadu\'s water conditions.',
                    items: allProducts.filter(p => p.category === 'Purifiers').slice(0, 3)
                }
            }
            // If no category rule matches, recommend Accessories or Filters as general add-ons
            activeRule = {
                targetCategory: 'Items',
                recommendCategory: 'Filters',
                reason: 'Stock up on essential replacement filters to ensure purity.'
            }
        }

        // 3. Select products based on rule
        const suggestedProducts = allProducts
            .filter((p) => p.category === activeRule.recommendCategory)
            // Exclude items already in cart
            .filter((p) => !cartItems.some((c) => c.id === p.id))
            .slice(0, 3)

        // If after filtering we have no products, fallback to Accessories
        if (suggestedProducts.length === 0) {
            return {
                title: 'Essential Accessories',
                reason: 'Complete your setup with these trending additions.',
                items: allProducts.filter(p => p.category === 'Accessories').slice(0, 3)
            }
        }

        return {
            title: cartItems.length > 0 ? `Recommended for your ${activeRule.targetCategory}` : 'Picks for You',
            reason: activeRule.reason,
            items: suggestedProducts
        }
    }, [allProducts, cartItems])

    return recommendations
}
