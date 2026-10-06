// /api/webhook/asaas.js - Vercel Function
import { createClient } from '@supabase/supabase-js'
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY)

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed')
  const { event: eventType, payment } = req.body
  if (!payment) return res.status(200).send('ok')
  const escritorioId = payment.externalReference
  try {
    if (eventType === 'PAYMENT_RECEIVED' || eventType === 'PAYMENT_CONFIRMED') {
      const plano = payment.description.includes('PRO') ? 'pro' : 'starter'
      const maxPoliciais = plano === 'pro' ? 999999 : 50
      await supabase.from('escritorios').update({ status: 'active', plano, max_policiais: maxPoliciais }).eq('id', escritorioId)
      await supabase.from('pagamentos').upsert({
        escritorio_id: escritorioId,
        asaas_payment_id: payment.id,
        valor: payment.value,
        status: 'RECEIVED',
        forma: payment.billingType,
        data_pagamento: new Date().toISOString()
      }, { onConflict: 'asaas_payment_id' })
    }
    if (eventType === 'PAYMENT_OVERDUE') {
      await supabase.from('escritorios').update({ status: 'past_due' }).eq('id', escritorioId)
    }
    return res.status(200).send('ok')
  } catch (e) {
    console.error(e)
    return res.status(500).send('error')
  }
}
