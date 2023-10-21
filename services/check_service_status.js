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

const fileName = basePath + '/services/' + env + (envType ? '.' + envType : '') + '.json';
const services = JSON.parse(fs.readFileSync(fileName, { encoding: 'utf8', flag: 'r' }));

var options = {
    headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true'
    },
    timeout: 60000
  };

checkServiceStatus(url.format("https://localhost:" + services.jenkins.port + "/login?from=%2F"), 'jenkins');
checkServiceStatus(url.format("https://localhost:" + services.neo4j.port), 'neo4j');
checkServiceStatus(url.format("https://localhost:" + services.nginx.port), 'nginx');

function checkServiceStatus (requestUrl, service) {
    if (!requestUrl) {
        logServiceState(service, 0, new Date().toString());
        return;
    }

    const request = https.get(requestUrl, options, (res) => {
        if (res) {
            logServiceState(service, res.statusCode, new Date().toString());
        };
    });

    request.on('timeout', () => {
        request.destroy();
    });

    request.on('error', (err) => {
        logServiceState(service, 0, new Date().toString(), err.message ? err.message.toString() : "");
    });
}

function logServiceState (service, statusCode, timestamp, errorMessage) {
    services[service]['current_state'] = (statusCode === 200) ? 1 : 0;
    services[service]['timestamp'] = timestamp;
    services[service]['errorMessage'] = errorMessage;

    if (services?.jenkins?.timestamp && services?.neo4j?.timestamp && services?.nginx?.timestamp) {
        fs.writeFileSync(fileName, JSON.stringify(services), 'utf-8');
    }
}