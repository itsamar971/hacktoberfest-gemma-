import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { OpenAI } from "https://deno.land/x/openai@v4.24.1/mod.ts"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { messages } = await req.json()
        const apiKey = Deno.env.get('OPENAI_API_KEY')
        const openai = new OpenAI({ apiKey })

        const systemPrompt = `
      You are a professional hiring manager and negotiation coach. 
      The user is negotiating their salary for a high-level role. 
      
      Rules:
      1. Respond as the recruiter. Be tough but fair.
      2. After your recruiter response, provide a "Strategy Tip" in brackets [Tip: ...] that explains what the user did well or how they can improve.
      3. Focus on: Anchoring, proving ROI, and Pivoting to other benefits.
      4. Keep the recruiter response natural and conversational.
    `

        const completion = await openai.chat.completions.create({
            model: "gpt-3.5-turbo",
            messages: [
                { role: "system", content: systemPrompt },
                ...messages
            ],
            temperature: 0.7,
        })

        const reply = completion.choices[0].message.content

        return new Response(
            JSON.stringify({ reply }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
