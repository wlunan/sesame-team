// Supabase Edge Function: 三数之和匹配算法
// 部署命令: supabase functions deploy match-scores

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 创建 Supabase 客户端
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const TARGET_SUM = 2026

    // 1. 获取所有待匹配的分数
    const { data: scores, error: fetchError } = await supabaseClient
      .from('scores')
      .select('*')
      .eq('status', 'pending')
      .order('score', { ascending: false }) // 优先高分

    if (fetchError) throw fetchError

    console.log(`Found ${scores.length} pending scores`)

    const matches = []
    const matched = new Set()

    // 2. 三数之和匹配算法
    for (let i = 0; i < scores.length; i++) {
      const s1 = scores[i]
      
      for (let j = i + 1; j < scores.length; j++) {
        const s2 = scores[j]
        const needed = TARGET_SUM - s1.score - s2.score

        // 查找第三个分数
        for (let k = j + 1; k < scores.length; k++) {
          const s3 = scores[k]
          
          if (s3.score === needed) {
            // 找到匹配组合
            matches.push({
              score_id_1: s1.id,
              score_id_2: s2.id,
              score_id_3: s3.id,
              total: TARGET_SUM,
              scores: [s1.score, s2.score, s3.score],
              emails: [s1.email, s2.email, s3.email],
              commands: [s1.command, s2.command, s3.command]
            })
            
            console.log(`Match found: ${s1.score} + ${s2.score} + ${s3.score} = ${TARGET_SUM}`)
            
            // 标记为已匹配（如果要限制只匹配一次，取消注释）
            // matched.add(s1.id)
            // matched.add(s2.id)
            // matched.add(s3.id)
          }
        }
      }
    }

    console.log(`Total matches found: ${matches.length}`)

    // 3. 保存匹配记录到数据库
    if (matches.length > 0) {
      const { data: insertedMatches, error: insertError } = await supabaseClient
        .from('matches')
        .insert(
          matches.map(m => ({
            score_id_1: m.score_id_1,
            score_id_2: m.score_id_2,
            score_id_3: m.score_id_3,
            total: m.total
          }))
        )
        .select()

      if (insertError) throw insertError

      // 4. 发送邮件通知（这里简化处理，实际需要集成邮件服务）
      for (const match of matches) {
        console.log('Match details:', {
          scores: match.scores,
          emails: match.emails,
          commands: match.commands
        })
        
        // TODO: 发送邮件通知
        // 可以使用 Resend、SendGrid 或其他邮件服务
        // await sendMatchNotification(match)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        matchesFound: matches.length,
        matches: matches
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

// 邮件通知函数（示例）
async function sendMatchNotification(match) {
  // 这里可以集成邮件服务
  // 例如使用 Resend API:
  
  // const resendApiKey = Deno.env.get('RESEND_API_KEY')
  
  // for (let i = 0; i < match.emails.length; i++) {
  //   const email = match.emails[i]
  //   const otherCommands = match.commands.filter((_, idx) => idx !== i)
  //   
  //   await fetch('https://api.resend.com/emails', {
  //     method: 'POST',
  //     headers: {
  //       'Authorization': `Bearer ${resendApiKey}`,
  //       'Content-Type': 'application/json'
  //     },
  //     body: JSON.stringify({
  //       from: 'noreply@yourdomain.com',
  //       to: email,
  //       subject: '🎉 匹配成功！',
  //       html: `
  //         <h2>恭喜！您的分数已匹配成功</h2>
  //         <p>您的分数: ${match.scores[i]}</p>
  //         <p>其他两位用户的口令:</p>
  //         <ul>
  //           <li>${otherCommands[0]}</li>
  //           <li>${otherCommands[1]}</li>
  //         </ul>
  //         <p>总和: ${match.total}</p>
  //       `
  //     })
  //   })
  // }
  
  console.log('Email notifications sent for match:', match)
}
