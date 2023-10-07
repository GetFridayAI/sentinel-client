const fs = require('fs'),
    https = require('https'),
    url = require('url');

let env, envType, basePath;

process.argv.map((arg)=>{
    if(arg.includes('env=')) {
        env = arg.replace('--env=', '');
    } else if(arg.includes('envType=')) {
        envType = arg.replace('--envType=', '');
    } else if(arg.includes('basePath=')) {
        basePath = arg.replace('--basePath=', '');
    }
});

const fileName = basePath + '/tunnels/' + env + (envType ? '.' + envType : '') + '.json';
const tunnels = JSON.parse(fs.readFileSync(fileName, { encoding: 'utf8', flag: 'r' }));

var options = {
    headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true'
    },
    timeout: 60000
  };

checkTunnelStatus(url.format(tunnels.jenkins.uri) + 'login?from=%2F', 'jenkins');
checkTunnelStatus(url.format(tunnels.neo4j.uri), 'neo4j');
checkTunnelStatus(url.format(tunnels.nginx.uri), 'nginx');

function checkTunnelStatus (requestUrl, service) {
    if (!requestUrl) {
        logTunnelState(service, 0, new Date().toString());
        return;
    }

    const request = https.get(requestUrl, options, (res) => {
        if (res) {
            logTunnelState(service, res.statusCode, new Date().toString());
        };
    });

    request.on('timeout', () => {
        request.destroy();
    });

    request.on('error', (err) => {
        logTunnelState(service, 0, new Date().toString(), err.message ? err.message.toString() : "");
    });
}

function logTunnelState (service, statusCode, timestamp, errorMessage) {
    tunnels[service]['current_state'] = (statusCode === 200) ? 1 : 0;
    tunnels[service]['timestamp'] = timestamp;
    tunnels[service]['errorMessage'] = errorMessage;

    if (tunnels?.jenkins?.timestamp && tunnels?.neo4j?.timestamp && tunnels?.nginx?.timestamp) {
        fs.writeFileSync(fileName, JSON.stringify(tunnels), 'utf-8');
    }
}