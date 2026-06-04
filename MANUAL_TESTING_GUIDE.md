#!/bin/bash
# Quick Testing Guide - Multi-Device Testing
# Execute this command to see the testing instructions

cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║           MULTI-DEVICE TESTING - QUICK GUIDE                   ║
║           Amerike MBA 2026 - Inversiones Simuladas             ║
╚════════════════════════════════════════════════════════════════╝

🌐 TESTING URL: http://192.168.100.15:9000
👤 ADMIN CREDENTIALS: admin / admin123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 STEP 1: SETUP (Do this first)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Open 3 browser windows:
   • Window 1: Chrome (Admin)
   • Window 2: Safari/Firefox (User 1)
   • Window 3: Different browser (User 2)

2. In each window, navigate to: http://192.168.100.15:9000

3. Login/Register:
   • Window 1: Login as "admin" / "admin123"
   • Window 2: Click "Registro como Invitado" → Create "usuario_test_1"
   • Window 3: Click "Registro como Invitado" → Create "usuario_test_2"

4. Verify all windows show "Connected" status

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 STEP 2: TEST FLOWS (Execute in order)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FLOW 1: Admin Starts Round
━━━━━━━━━━━━━━━━━━━━━━━━
1. In Window 1 (Admin): Click "Iniciar Nueva Ronda"
2. Set round parameters and confirm
3. ✅ Check: ALL windows show "Ronda Activa" 
4. ✅ Check: ALL windows show same round ID
5. ✅ Check: Invest buttons are enabled on Windows 2 & 3

Expected sync time: < 2 seconds


FLOW 2: Users Invest
━━━━━━━━━━━━━━━━━━━━
1. Window 2 (User 1): Invest $1000 in "Startup Tech"
2. Window 3 (User 2): Invest $1500 in "Real Estate"
3. ✅ Check: Window 2 confirms investment locally
4. ✅ Check: Window 3 confirms investment locally
5. ✅ Check: Window 1 (Admin) sees both investments
6. ✅ Check: Ranking updates in ALL 3 windows
7. ✅ Check: Ranking is consistent across windows

Expected sync time: < 1 second per investment


FLOW 3: Admin Pauses Round
━━━━━━━━━━━━━━━━━━━━━━━
1. Window 1 (Admin): Click "Pausar Ronda"
2. ✅ Check: ALL windows show "Ronda Pausada"
3. ✅ Check: Invest buttons disabled on Windows 2 & 3
4. Window 2 (User 1): Try to invest → Should show error
5. Window 1 (Admin): Click "Reanudar Ronda"
6. ✅ Check: ALL windows return to "Ronda Activa"
7. ✅ Check: Invest buttons re-enabled

Expected sync time: < 1 second


FLOW 4: Admin Ends Round
━━━━━━━━━━━━━━━━━━━━━
1. Window 1 (Admin): Click "Terminar Ronda"
2. ✅ Check: ALL windows show "Ronda Finalizada"
3. ✅ Check: Window 2 shows final position
4. ✅ Check: Window 3 shows final position
5. ✅ Check: Final ranking is consistent
6. ✅ Check: No more investments allowed

Expected sync time: < 2 seconds

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 STEP 3: STRESS TEST (Optional but recommended)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Admin starts new round
2. User 1 & User 2 make 5 investments each, alternating quickly
3. Monitor for:
   • No crashes in any window
   • No console errors
   • All investments recorded correctly
   • Ranking updates correctly
   • No duplicate or lost investments

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 STEP 4: RECONNECTION TEST (Optional but recommended)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Window 2: Turn off WiFi (disconnect network)
2. Wait 5 seconds
3. Window 2: Turn on WiFi (reconnect network)
4. Window 1: Make a visible change (pause/resume)
5. ✅ Check: Window 2 shows "Disconnected" during offline
6. ✅ Check: Window 2 reconnects automatically
7. ✅ Check: Window 2 receives the change and syncs properly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 STEP 5: COLLECT LOGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Browser Console (in each window):
1. Open Developer Tools (F12 or Cmd+Option+I)
2. Go to Console tab
3. Look for WebSocket messages and errors
4. Document any red/yellow messages

Server Logs:
   tail -f /Users/raxgomez/Documents/MBA/Tania/websocket-server/logs/app.log

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ SUCCESS CRITERIA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MVP (Minimum Viable Product):
• Users can connect simultaneously
• Rankings sync in real-time
• No crashes during basic testing

Optimized:
• Latency < 500ms in all flows
• Automatic reconnection works
• Stress test passes without errors

Excellent:
• Latency < 200ms in all flows
• Robust disconnection handling
• UI updates instantly
• Clean logs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Update results in:
   /Users/raxgomez/Documents/MBA/Tania/MULTI_DEVICE_TESTING_RESULTS.md

Full protocol:
   /Users/raxgomez/Documents/MBA/Tania/MULTI_DEVICE_TESTING_REPORT.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF