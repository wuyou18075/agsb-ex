#!/usr/bin/env bash
# =============================================================================
# test.sh - Online testing: speed test, Argo speed test, network tuning
# =============================================================================

generate_speedtest_html() {
  mkdir -p /etc/sing-box/node-info
  SPEED_IP="$(curl -4fsS --connect-timeout 5 --max-time 15 https://api.ipify.org 2>/dev/null || curl -4fsS --connect-timeout 5 --max-time 15 https://ipv4.icanhazip.com 2>/dev/null || echo 'get IP failed')"
  SPEED_PORT="$(shuf -i 50000-60000 -n 1 2>/dev/null || echo '58888')"
  while port_in_use "$SPEED_PORT" 2>/dev/null; do SPEED_PORT="$(shuf -i 50000-60000 -n 1 2>/dev/null || echo '58888')"; done
  export SPEED_PORT

  cat > /etc/sing-box/node-info/speedtest.html << 'SPDT_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>CF Domain Speed Test</title>
<style>
:root{color-scheme:light}
body{font-family:system-ui,-apple-system,sans-serif;background:#f5f5f5;margin:0;padding:20px}
.container{max-width:800px;margin:0 auto}
h1{font-size:24px;margin:0 0 10px}
.info{color:#666;margin:0 0 8px;font-size:13px}
.warn{background:#fff3cd;border-radius:6px;padding:10px;margin:0 0 15px;font-size:13px}
.rec{background:#e8f5e9;border-radius:8px;padding:12px;margin:0 0 20px;font-size:13px}
.rec strong{color:#2e7d32}
table{width:100%;border-collapse:collapse;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)}
th{background:#333;color:#fff;padding:10px 12px;text-align:left;font-size:14px}
td{padding:8px 12px;border-bottom:1px solid #eee;font-size:14px}
tr:hover{background:#f0f7ff}
.bar{display:inline-block;height:14px;border-radius:3px;margin-right:6px;vertical-align:middle}
.fast{background:#4caf50}.mid{background:#ff9800}.slow{background:#f44336}.wait{background:#ccc;animation:pulse 1s infinite}
@keyframes pulse{50%{opacity:.5}}
.btn{display:inline-block;padding:10px 20px;background:#1976d2;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:14px;margin:10px 5px 0 0}
.btn:hover{background:#1565c0}
.result{font-size:12px;color:#888;margin:10px 0}
</style>
</head>
<body>
<div class="container">
<h1>Cloudflare Preferred Domain Speed Test</h1>
<p class="info">Your IP: <strong id="myip">detecting...</strong></p>
<div class="warn"><strong>Note:</strong> If using proxy/VPN, test measures proxy latency. Close proxy for real local latency.</div>
<div id="ipv6-notice" class="warn" style="display:none;background:#d1ecf1"><strong>IPv6 detected:</strong> CF domain optimization has minimal effect for IPv6 users. Close page and return to terminal.</div>
<div class="rec">
<strong>ISP recommendations:</strong><br>
Telecom - visa.cn / shopify.com / cf.877774.xyz<br>
Unicom - cloudflare-dl.byoip.top / saas.sin.fan<br>
Mobile - bestcf.030101.xyz / cf.090227.xyz<br>
Unknown - www.visa.cn (best domestic CDN)
</div>
<button class="btn" onclick="startTest()">Start Test (30 domains)</button>
<button class="btn" onclick="stopTest()">Stop</button>
<button class="btn" onclick="submitDomains()" style="background:#4caf50">Submit Selected to VPS</button>
<p class="result" id="status">Click "Start Test" to begin</p>
<table id="results">
<thead><tr><th>#</th><th>Domain</th><th>Note</th><th>Latency (ms)</th><th>Select</th></tr></thead>
<tbody id="tbody"></tbody>
</table>
</div>
<script>
var domains=[
{d:"www.visa.cn",n:"Visa China"},{d:"www.shopify.com",n:"Shopify"},{d:"www.apple.com",n:"Apple"},
{d:"www.bing.com",n:"MS Bing"},{d:"www.cloudflare.com",n:"Cloudflare"},{d:"arxiv.org",n:"Cornell"},
{d:"dl.acm.org",n:"ACM"},{d:"www.semanticscholar.org",n:"AI2"},{d:"www.sciencedirect.com",n:"Elsevier"},
{d:"www.nature.com",n:"Nature"},{d:"www.ieee.org",n:"IEEE"},{d:"time.is",n:"time.is"},
{d:"mfa.gov.ua",n:"MFA Ukraine"},{d:"store.ubi.com",n:"Ubisoft"},{d:"staticdelivery.nexusmods.com",n:"NexusMods"},
{d:"icook.hk",n:"icook HK"},{d:"icook.tw",n:"icook TW"},{d:"cloudflare-dl.byoip.top",n:"NB preferred"},
{d:"cf.877774.xyz",n:"QMS"},{d:"saas.sin.fan",n:"MIYU"},{d:"bestcf.030101.xyz",n:"Mingyu mobile"},
{d:"cf.090227.xyz",n:"CM maintained"},{d:"cdn.2020111.xyz",n:"cdn.2020111"},{d:"cdns.doon.eu.org",n:"cdns.doon"},
{d:"cf.0sm.com",n:"cf.0sm"},{d:"cf.900501.xyz",n:"cf.900501"},{d:"cfip.1323123.xyz",n:"cfip.1323123"},
{d:"cfip.cfcdn.vip",n:"cfip.cfcdn"},{d:"cloudflare-ip.mofashi.ltd",n:"mofashi"},{d:"fn.130519.xyz",n:"fn.130519"}
];
var running=false,results=[],selected=new Set(),CONCURRENCY=15;

(function(){
  var ipDisplayed = false;
  function showIP(ip, via){
    if(ipDisplayed) return;
    ipDisplayed = true;
    var el = document.getElementById("myip");
    if(ip.indexOf(":") >= 0){
      el.innerHTML = ip + ' <span style=color:#888>(' + via + ', IPv6)</span>';
      document.getElementById("ipv6-notice").style.display = "block";
    } else {
      el.innerHTML = ip + ' <span style=color:#888>(' + via + ')</span>';
    }
  }
  try{
    var pc = new (window.RTCPeerConnection||window.webkitRTCPeerConnection)({iceServers:[]});
    pc.createDataChannel("");
    pc.onicecandidate = function(e){
      if(e && e.candidate && e.candidate.candidate){
        var parts = e.candidate.candidate.split(" ");
        if(parts.length >= 5){
          var ip = parts[4];
          if(ip && !ip.startsWith("192.168.") && !ip.startsWith("10.") && !ip.startsWith("172.1") && !ip.startsWith("0.") && !ip.startsWith("127.") && !ip.startsWith("fe80:") && !ip.startsWith("fc") && !ip.startsWith("fd") && ip.indexOf(".local") < 0){
            showIP(ip, "local IP, bypassed proxy");
            pc.close();
          }
        }
      }
    };
    pc.createOffer().then(function(s){pc.setLocalDescription(s)});
  }catch(e){}
  var ipDone = false;
  function multiFallback(){
    if(ipDone) return;
    ipDone = true;
    var timedOut = false;
    var t = setTimeout(function(){ timedOut = true; }, 5000);
    function extractIp(resp){ if(resp && resp.ip) return resp.ip; if(typeof resp === "string" && resp.trim()) return resp.trim(); return null; }
    Promise.any([
      fetch("https://api.ipify.org?format=json", {mode: "cors"}).then(function(r){return r.json()}),
      fetch("https://ipv4.icanhazip.com/", {mode: "cors"}).then(function(r){return r.text()}),
      fetch("https://api.ip.sb/geoip", {mode: "cors"}).then(function(r){return r.json()}),
      fetch("https://api6.ipify.org?format=json", {mode: "cors"}).then(function(r){return r.json()})
    ]).then(function(result){
      if(!timedOut){ var ip = extractIp(result); if(ip) showIP(ip, "via external API"); }
    }).catch(function(){
      if(!timedOut){
        fetch("/myip", {mode: "cors"}).then(function(r){return r.text()}).then(function(ip){
          if(ip && ip.trim() && !timedOut) showIP(ip.trim(), "detected by VPS");
        }).catch(function(){
          if(!timedOut) showIP("unavailable", "all methods failed");
        });
      }
    }).finally(function(){ clearTimeout(t); });
  }
  setTimeout(function(){ if(!ipDisplayed) multiFallback(); }, 2000);
  setTimeout(function(){ if(!ipDisplayed) document.getElementById("myip").innerHTML = 'failed <span style=color:#888>(browser restriction)</span>'; }, 7000);
})();

function init(){var t=document.getElementById("tbody");t.innerHTML="";domains.forEach(function(d,i){var r=document.createElement("tr");r.id="row-"+i;r.innerHTML="<td>"+(i+1)+"</td><td>"+d.d+"</td><td>"+d.n+"</td><td id=lat-"+i+"><span class='bar wait' style=width:60px></span></td><td><input type=checkbox id=chk-"+i+" onchange=toggle("+i+")></td>";t.appendChild(r)})}
function toggle(i){var c=document.getElementById("chk-"+i);c.checked?selected.add(i):selected.delete(i);updateSel()}
function updateSel(){var s=[...selected].sort((a,b)=>a-b).map(i=>domains[i].d);document.getElementById("status").textContent=s.length?"selected: "+s.join(", "):"check the fastest domains"}
function pingOnce(d){return new Promise(function(resolve){var s=performance.now();var c=new AbortController();var to=setTimeout(function(){c.abort();resolve(9999)},5000);fetch("https://"+d+"/favicon.ico?"+Math.random(),{mode:"no-cors",cache:"no-cache",signal:c.signal}).then(function(){clearTimeout(to);resolve(Math.round(performance.now()-s))}).catch(function(){clearTimeout(to);if(performance.now()-s<4900){resolve(Math.round(performance.now()-s))}else{resolve(9999)}})})}
function testOne(i){if(!running)return;var d=domains[i];return Promise.all([pingOnce(d.d),pingOnce(d.d),pingOnce(d.d)]).then(function(ms){results[i]=Math.min.apply(null,ms);updateRow(i)})}
function updateRow(i){var m=results[i],t=document.getElementById("lat-"+i),c=m<200?"fast":m<500?"mid":"slow",w=m<200?m:200+(m-200)/3;c=m>=5000?"slow":c;t.innerHTML="<span class='bar "+c+"' style=width:"+Math.min(w,300)+"px></span> "+(m>=9999?"timeout":m+" ms")}
async function startTest(){
  running=true;results=[];selected.clear();
  init();
  var statusEl=document.getElementById("status");
  statusEl.textContent="testing... (concurrency "+CONCURRENCY+")";
  for(var i=0;i<domains.length&&running;i+=CONCURRENCY){
    var batch=[];
    for(var j=i;j<Math.min(i+CONCURRENCY,domains.length)&&running;j++){
      (function(idx){batch.push(testOne(idx));})(j);
    }
    await Promise.all(batch);
  }
  if(running){
    var sorted=results.map(function(r,i){return{r:i}}).filter(function(x){return x.r<9000}).sort(function(a,b){return a.r-b.r});
    selected.clear();
    sorted.slice(0,5).forEach(function(x){selected.add(x.i);document.getElementById("chk-"+x.i).checked=true});
    updateSel();
    statusEl.textContent="done! fastest 5 auto-selected. submit to VPS.";
    running=false;
  }
}
function submitDomains(){
  var sel=[...selected].sort((a,b)=>a-b).map(i=>domains[i].d);
  if(sel.length===0){alert("select domains first");return}
  document.getElementById("status").textContent="submitting...";
  fetch("/submit",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({domains:sel})})
  .then(function(r){return r.json()}).then(function(d){
    var ipInfo = d.client_ip ? "VPS sees you as: " + d.client_ip + "<br>" : "";
    document.getElementById("status").innerHTML="<span style='color:#4caf50'>submitted "+d.count+" domains:<br>"+d.domains.join(", ")+"</span><br>"+ipInfo+"<span style='color:#888'>close page, return to terminal</span>";
  }).catch(function(e){document.getElementById("status").innerHTML="<span style='color:red'>submit failed</span>, check VPS server";});
}
function stopTest(){running=false;document.getElementById("status").textContent="stopped"}
init();
</script>
</body>
</html>
SPDT_EOF

  echo
  cyan "--- local browser speed test ---"
  echo "open in browser (disable proxy for accurate results):"
  echo ""
  echo "  http://${SPEED_IP:-get IP failed}:${SPEED_PORT:-58888}/speedtest.html"
  echo ""
  yellow "measures YOUR latency to CF domains. select fastest and submit."
  echo "(server auto-stops after 60s)"
  echo ""

  (cd /etc/sing-box/node-info && SPEED_PORT="${SPEED_PORT}" python3 << 'SRVEOF' &
import http.server, json, os, datetime
PORT = int(os.environ.get("SPEED_PORT","8888"))
SAVE = "/etc/sing-box/node-info/selected_domains.txt"

class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/myip":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(self.client_address[0].encode("utf-8"))
            return
        super().do_GET()
    def do_POST(self):
        if self.path != "/submit":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length", 0))
        data = json.loads(self.rfile.read(length))
        domains = data.get("domains", [])
        client_ip = self.client_address[0]
        ts = datetime.datetime.now().strftime("%H:%M:%S")
        with open(SAVE, "w") as f:
            f.write(",".join(domains))
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        resp = json.dumps({"ok": True, "count": len(domains), "domains": domains, "client_ip": client_ip}, ensure_ascii=False)
        self.wfile.write(resp.encode("utf-8"))
        print("[%s] Received from %s: %s" % (ts, client_ip, ", ".join(domains)))
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
    def log_message(self, *a):
        pass

srv = http.server.HTTPServer(("0.0.0.0", PORT), H)
srv.timeout = 60
try:
    print("Speedtest server on port %d" % PORT)
    srv.serve_forever()
except:
    pass
SRVEOF
  )
  sleep 60
  kill %1 2>/dev/null || true
}

argo_speedtest_and_select() {
  select_argo_edge_server
}

tune_proxy_machine() {
  require_root
  local tune_choice ssh_host rtt i url lat lat_ms best_url best_latency speed_urls speed_labels best_buffer best_buffer_bytes
  echo
  cyan "========== 代理机器调优 =========="
  echo "1) 自动测速选优（推荐）"
  echo "2) 仅查看当前 SSH 延迟"
  echo "0) 返回"
  read -r -p "请选择 [默认: 1]: " tune_choice
  tune_choice="${tune_choice:-1}"
  [[ "$tune_choice" == "0" ]] && return
  echo
  yellow "--- SSH 延迟检测 ---"
  ssh_host="${SSH_CONNECTION%% *}"
  if [[ -z "$ssh_host" ]]; then
    ssh_host="$(curl -4 -fsS --connect-timeout 5 --max-time 10 https://api.ipify.org 2>/dev/null || true)"
    rtt="N/A"
  else
    rtt="$(ping -c 3 -W 2 "$ssh_host" 2>/dev/null | tail -1 | awk -F/ '{print int($5)}' 2>/dev/null || echo "N/A")"
  fi
  echo "SSH 连接端: ${ssh_host:-unable to detect}"
  echo "延迟 RTT:   ${rtt} ms"
  echo
  [[ "$tune_choice" != "1" ]] && return
  yellow "--- 国内友好测速点检测（选延迟最低的） ---"
  speed_urls=("https://www.visa.com" "https://www.speedtest.net" "https://time.cloudflare.com")
  speed_labels=("www.visa.com" "www.speedtest.net" "time.cloudflare.com")
  best_latency="999999"
  for i in "${!speed_urls[@]}"; do
    url="${speed_urls[$i]}"
    label="${speed_labels[$i]}"
    printf "  测速 %s ... " "$label"
    lat="$(curl -o /dev/null -sS --connect-timeout 5 --max-time 15 -w "%{time_total}" "$url" 2>/dev/null || echo "999")"
    lat_ms="$(awk -v t="$lat" 'BEGIN {printf "%d", t*1000}' 2>/dev/null)"
    echo "${lat_ms} ms"
    if [[ "$lat_ms" -lt "$best_latency" ]]; then
      best_latency="$lat_ms"
      best_url="$label"
    fi
  done
  echo
  if [[ -n "$best_url" && "$best_latency" -lt 999999 ]]; then
    green "最佳测速点: ${best_url} (${best_latency} ms)"
    yellow "正在根据延迟应用最优 TCP 参数..."
    best_buffer="$(calculate_bbr_buffer_mb)"
    best_buffer_bytes=$((best_buffer * 1024 * 1024))
    mkdir -p "$(dirname "$BBR_SYSCTL")"
    cat > "$BBR_SYSCTL" <<EOF
# Generated by ${APP_NAME} auto-tune
net.core.default_qdisc = fq
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.core.rmem_max = ${best_buffer_bytes}
net.core.wmem_max = ${best_buffer_bytes}
net.ipv4.tcp_rmem = 4096 87380 ${best_buffer_bytes}
net.ipv4.tcp_wmem = 4096 65536 ${best_buffer_bytes}
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.udp_rmem_min = 4096
net.ipv4.udp_wmem_min = 4096
net.core.udp_mem = ${best_buffer_bytes} $((best_buffer_bytes / 4))
EOF
  fi
  if sysctl -p "$BBR_SYSCTL" >/dev/null 2>&1; then
    green "TCP 参数已应用"
  else
    yellow "部分参数应用失败，请检查系统兼容性"
  fi
  green "代理机器调优完成"
}

enable_fq_qdisc() {
  require_root
  local iface
  iface="$(ip route show default | awk '{print $5; exit}')"
  if [[ -z "$iface" ]]; then
    red "未检测到默认网卡"
    return
  fi
  if tc qdisc replace dev "$iface" root fq 2>/dev/null; then
    green "fq qdisc 已生效（${iface}）"
  else
    red "开启 fq 失败"
  fi
}

enable_cake_qdisc() {
  require_root
  local iface bw
  iface="$(ip route show default | awk '{print $5; exit}')"
  if [[ -z "$iface" ]]; then
    red "未检测到默认网卡"
    return
  fi
  bw="$(ethtool "$iface" 2>/dev/null | awk '/Speed:/ {print $2; exit}' || true)"
  [[ -n "$bw" ]] && bw="${bw}bit" || bw="1gbit"
  if tc qdisc replace dev "$iface" root cake bandwidth "$bw" 2>/dev/null; then
    green "cake qdisc 已生效（${iface}, bandwidth ${bw}）"
  else
    red "开启 cake 失败"
  fi
}

install_bbrv3_only() {
  require_root
  install_packages "0"
  install_bbrv3_kernel
  if [[ "${BBRV3_REBOOT_REQUIRED:-0}" == "1" ]]; then
    prompt_reboot_for_bbrv3
  fi
}

install_bbrv3_kernel() {
  local codename cpu_level current_kernel install_pkg="" key_tmp

  current_kernel="$(uname -r 2>/dev/null || true)"
  if [[ "$current_kernel" == *xanmod* ]]; then
    green "当前已运行 XanMod 内核：${current_kernel}"
    enable_bbr
    return 0
  fi

  cpu_level="$(detect_x86_64_level || true)"
  if [[ -z "$cpu_level" ]]; then
    yellow "当前 CPU / 虚拟化环境暂不支持自动选择 XanMod x86_64 内核包。"
    yellow "将继续安装协议，并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi

  codename="$(detect_apt_codename)"
  if [[ -z "$codename" ]]; then
    yellow "无法识别 Debian / Ubuntu 发行版代号，跳过 XanMod 源。"
    yellow "将继续安装协议，并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi

  yellow "正在添加 XanMod 官方源并安装适配 CPU x86-64-v${cpu_level} 的 BBRv3 内核。"
  mkdir -p "$(dirname "$XANMOD_KEYRING")"
  key_tmp="$(mktemp)"
  if ! download_xanmod_key "$key_tmp"; then
    rm -f "$key_tmp"
    yellow "将跳过强制更换 XanMod 内核，继续安装协议并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi
  if ! gpg --dearmor --yes -o "$XANMOD_KEYRING" "$key_tmp"; then
    rm -f "$key_tmp"
    yellow "XanMod GPG key 转换失败，将跳过强制更换内核并继续安装协议。"
    enable_bbr
    return 0
  fi
  rm -f "$key_tmp"
  chmod 0644 "$XANMOD_KEYRING"
  printf 'deb [signed-by=%s] http://deb.xanmod.org %s main\n' "$XANMOD_KEYRING" "$codename" > "$XANMOD_APT_LIST"

  if ! apt-get update; then
    yellow "XanMod 源刷新失败，将跳过强制更换内核并继续安装协议。"
    enable_bbr
    return 0
  fi
  install_pkg="$(select_xanmod_package "$cpu_level" || true)"
  if [[ -z "$install_pkg" ]]; then
    yellow "XanMod 源中未找到适配 x86-64-v${cpu_level} 的可用内核包。"
    yellow "将跳过强制更换 XanMod 内核，继续安装协议并应用当前内核可用的 TCP/BBR 调优。"
    enable_bbr
    return 0
  fi
  yellow "将安装 XanMod 内核包：${install_pkg}"
  if [[ "$cpu_level" == "4" && "$install_pkg" == *x64v3* ]]; then
    yellow "说明：XanMod 当前常用包以 x64v3 为主，x86-64-v4 CPU 使用 x64v3 包。"
  fi

  if ! apt-get install -y "$install_pkg"; then
    yellow "${install_pkg} 安装失败，将跳过强制更换 XanMod 内核，继续安装协议。"
    enable_bbr
    return 0
  fi
  set_grub_default_first_entry
  refresh_grub_config
  enable_bbr

  if [[ "$(uname -r 2>/dev/null || true)" == *xanmod* ]]; then
    green "BBRv3 / XanMod 内核已生效：$(uname -r)"
  else
    BBRV3_REBOOT_REQUIRED="1"
    yellow "BBRv3 / XanMod 内核已安装，重启 VPS 后才会真正生效。"
    yellow "建议安装完成、保存节点后执行: reboot"
  fi
}

enable_bbr() {
  local buffer_bytes buffer_mb cc core_buffer_bytes optmem_bytes qdisc available want_bbr=0

  if ! command -v sysctl >/dev/null 2>&1; then
    yellow "未找到 sysctl，已跳过 TCP/BBR 调优。"
    return 0
  fi

  clean_bbr_sysctl_conflicts
  buffer_mb="$(calculate_bbr_buffer_mb)"
  buffer_bytes=$((buffer_mb * 1024 * 1024))
  core_buffer_bytes=$((buffer_bytes * 2))
  if [[ "$core_buffer_bytes" -gt 134217728 ]]; then
    core_buffer_bytes=134217728
  fi
  optmem_bytes="$buffer_bytes"
  if [[ "$optmem_bytes" -gt 67108864 ]]; then
    optmem_bytes=67108864
  fi

  modprobe tcp_bbr >/dev/null 2>&1 || true
  # If modprobe failed, try installing linux-modules-extra for current kernel
  if ! sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
    if command -v apt-get >/dev/null 2>&1; then
      local ker_ver
      ker_ver="$(uname -r)"
      apt-get install -y -qq "linux-modules-extra-${ker_ver}" 2>/dev/null || true
      modprobe tcp_bbr >/dev/null 2>&1 || true
      modprobe tcp_bbr2 >/dev/null 2>&1 || true
    fi
  fi
  available="$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || true)"
  if printf '%s\n' "$available" | grep -qw bbr; then
    want_bbr=1
  else
    yellow "当前内核未提供 BBR，将先应用通用 TCP 调优。可用拥塞控制: ${available:-unknown}"
  fi

  cat > "$BBR_SYSCTL" <<EOF
# Generated by ${APP_NAME}. Optimized for TCP proxy throughput and latency.
net.core.default_qdisc = fq
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = ${core_buffer_bytes}
net.core.wmem_max = ${core_buffer_bytes}
net.core.optmem_max = ${optmem_bytes}
net.ipv4.tcp_rmem = 4096 87380 ${buffer_bytes}
net.ipv4.tcp_wmem = 4096 65536 ${buffer_bytes}
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_syncookies = 1
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
EOF

  if [[ "$want_bbr" == "1" ]]; then
    printf 'net.ipv4.tcp_congestion_control = bbr\n' >> "$BBR_SYSCTL"
  fi

  sysctl -e -p "$BBR_SYSCTL" >/dev/null 2>&1 || true

  # 网卡中断合并优化（降低延迟）
  local _iface
  _iface="$(ip route show default | awk '{print $5; exit}' 2>/dev/null || true)"
  if [[ -n "$_iface" ]] && command -v ethtool >/dev/null 2>&1; then
    ethtool -C "$_iface" adaptive-rx off adaptive-tx off rx-usecs 8 tx-usecs 8 2>/dev/null || true
  fi

  cc="$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
  qdisc="$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"
  if [[ "$cc" == "bbr" ]]; then
    green "TCP/BBR 调优已应用：tcp_congestion_control=${cc}, default_qdisc=${qdisc:-unknown}, tcp_buffer=${buffer_mb}MB"
  else
    green "TCP 调优已应用；当前拥塞控制为: ${cc:-unknown}, default_qdisc=${qdisc:-unknown}, tcp_buffer=${buffer_mb}MB"
  fi
}

prompt_reboot_for_bbrv3() {
  local ans=""

  echo
  yellow "BBRv3 内核已安装，新内核必须重启 VPS 后才会生效。"
  yellow "请确认节点信息已保存；按回车立即重启，输入 n 稍后手动重启。"
  read -r -p "立即重启？[Y/n]: " ans
  if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
    sync || true
    yellow "正在重启 VPS..."
    if command -v systemctl >/dev/null 2>&1; then
      systemctl reboot || reboot
    else
      reboot
    fi
    exit 0
  fi

  yellow "已取消自动重启。稍后执行 reboot 后，菜单 4 可查看 kernel / tcp_cc。"
}

detect_public_ipv4() {
  local ip url
  for url in \
    "https://api.ipify.org" \
    "https://ipv4.icanhazip.com" \
    "https://ifconfig.me/ip"; do
    ip="$(curl -4 -fsS --connect-timeout 5 --max-time 10 "$url" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ -n "$ip" ]] && is_global_ipv4 "$ip"; then
      printf '%s\n' "$ip"
      return 0
    fi
  done
  return 1
}

preferred_direct_server_addr() {
  local a_records ipv4

  if [[ -n "${DIRECT_SERVER_ADDR:-}" ]]; then
    printf '%s\n' "$DIRECT_SERVER_ADDR"
    return 0
  fi

  if [[ -z "${DOMAIN:-}" ]]; then
    return 1
  fi

  a_records="$(resolve_domain_ips 4 "$DOMAIN" || true)"
  if [[ -n "$a_records" ]]; then
    DIRECT_SERVER_ADDR="$DOMAIN"
    printf '%s\n' "$DIRECT_SERVER_ADDR"
    return 0
  fi

  if ipv4="$(detect_public_ipv4)"; then
    DIRECT_SERVER_ADDR="$ipv4"
  else
    DIRECT_SERVER_ADDR="$DOMAIN"
  fi

  printf '%s\n' "$DIRECT_SERVER_ADDR"
}
