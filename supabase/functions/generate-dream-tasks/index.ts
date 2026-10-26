import "https://deno.land/x/xhr@0.3.0/mod.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { OpenAI } from "https://deno.land/x/openai@v4.24.1/mod.ts";

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders });
    }

    try {
        const { dream, days } = await req.json();

        if (!dream) {
            throw new Error('Missing dream description');
        }

        const duration = days || 7; // Default to 7 days if not provided

        const apiKey = Deno.env.get('OPENAI_API_KEY');
        if (!apiKey) {
            throw new Error('OPENAI_API_KEY is not set');
        }

        const openai = new OpenAI({
            apiKey: apiKey,
        });

        const systemPrompt = `
      You are an expert productivity coach. 
      Break down the user's dream goal into a ${duration}-day plan of tiny, actionable micro-steps.
      Each step must take less than 20 minutes to complete.
      
      Return ONLY a raw JSON array of objects (no markdown, no code blocks).
      Each object must have:
      - "title": A short, action-oriented task description (max 10 words).
      - "duration": Estimated minutes (integer, 5-20).
      
      Example:
      [
        {"title": "Research best local running trails", "duration": 15},
        {"title": "Buy comfortable running shoes", "duration": 20}
      ]
    `;

        const userPrompt = `My dream is: "${dream}". Give me a ${duration}-day plan.`;

        const completion = await openai.chat.completions.create({
            model: 'gpt-4o', // or gpt-3.5-turbo if unavailable
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userPrompt },
            ],
            temperature: 0.7,
        });

        const responseContent = completion.choices[0].message.content;

        // Parse JSON safely (removing any markdown block code if AI adds it)
        let tasks = [];
        try {
            const cleanJson = responseContent.replace(/```json/g, '').replace(/```/g, '').trim();
            tasks = JSON.parse(cleanJson);
        } catch (e) {
            console.error("JSON Parse Error:", e);
            // Fallback or simplistic parse if needed
            throw new Error("Failed to parse AI response into valid JSON");
        }

        return new Response(
            JSON.stringify({ tasks: tasks }),
            {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 200,
            },
        );

    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                status: 400,
            },
        );
    }
});
