const fs = require('fs'),
    firebase = require('firebase/app'),
    database = require('firebase/database'),
    auth = require('firebase/auth');

let firebaseConfig = {
    "apiKey": "",
    "authDomain": "",
    "databaseURL": "",
    "projectId": "",
    "storageBucket": "",
    "messagingSenderId": "",
    "appId": ""
}, env, envType, email, password, dbBasePath, basePath;

process.argv.map((arg)=>{
    if(arg.includes('apiKey=')) {
        firebaseConfig.apiKey = arg.replace('--apiKey=', '');
    } else if(arg.includes('appId=')) {
        firebaseConfig.appId = arg.replace('--appId=', '');
    } else if(arg.includes('dbUrl=')) {
        firebaseConfig.databaseURL = arg.replace('--dbUrl=', '');
    } else if(arg.includes('projectId=')) {
        firebaseConfig.projectId = arg.replace('--projectId=', '');
    } else if(arg.includes('authDomain=')) {
        firebaseConfig.authDomain = arg.replace('--authDomain=', '');
    } else if(arg.includes('storageBucket=')) {
        firebaseConfig.storageBucket = arg.replace('--storageBucket=', '');
    } else if(arg.includes('msgSenderId=')) {
        firebaseConfig.messagingSenderId = arg.replace('--msgSenderId=', '');
    } else if(arg.includes('env=')) {
        env = arg.replace('--env=', '');
    } else if(arg.includes('envType=')) {
        envType = arg.replace('--envType=', '');
    } else if(arg.includes('email=')) {
        email = arg.replace('--email=', '');
    } else if(arg.includes('password=')) {
        password = arg.replace('--password=', '');
    } else if(arg.includes('dbBasePath=')) {
        dbBasePath = arg.replace('--dbBasePath=', '');
    } else if(arg.includes('basePath=')) {
        basePath = arg.replace('--basePath=', '');
    }
});

const fileName = basePath + '/tunnels/' + env + (envType ? '.' + envType : '') + '.json';
const tunnels = JSON.parse(fs.readFileSync(fileName, { encoding: 'utf8', flag: 'r' }));
const areAllTunnelsUp = Object.keys(tunnels).filter((service) => { return tunnels[service]['current_state'] === 0 }).length === 0;

if (areAllTunnelsUp) fs.rmSync(fileName);

function updateData() {
    const db = database.getDatabase(app);
    const dbRefPath = dbBasePath + "/" + env + "/" + (envType ? envType + "/" : "");
    const sentinelRecordsRef = database.ref(db, dbRefPath);

    database.onValue(sentinelRecordsRef, async (snapshot, err) => {
        if(err) {
            console.log(err);
        }
        const dbSnapshot = Object.assign({}, snapshot.val());
        let modifiedDbSnapshot = {};
        
        if (!dbSnapshot.performance) {
            dbSnapshot.performance = {};
        }
        
        if (!dbSnapshot.performance.tunnels) {
            dbSnapshot.performance.tunnels = {
                jenkins: [],
                nginx: [],
                neo4j: []
            }
        } else {
            if (!dbSnapshot.performance.tunnels.jenkins) {
                dbSnapshot.performance.tunnels.jenkins = [];
            }

            if (!dbSnapshot.performance.tunnels.neo4j) {
                dbSnapshot.performance.tunnels.neo4j = [];
            }

            if (!dbSnapshot.performance.tunnels.nginx) {
                dbSnapshot.performance.tunnels.nginx = [];
            }
        }

        await Promise.all(Object.keys(tunnels).map((service) => {
            const isTunnelRunning = tunnels[service]['current_state'] === 1;
            const log = {
                timestamp: tunnels[service]['timestamp'],
                data: {
                    isRunning: isTunnelRunning.toString(),
                    errorMessage: tunnels[service]['errorMessage'] ? tunnels[service]['errorMessage'] : 'null'
                }
            }
            dbSnapshot.performance.tunnels[service].push(log);
            if (isTunnelRunning) {
                dbSnapshot.specs.public_tunnels[service]['last_activity_check'] = tunnels[service]['timestamp'];
            }
        }));

        modifiedDbSnapshot[dbRefPath] = dbSnapshot;
        database.update(database.ref(db), modifiedDbSnapshot);
        process.exit(0);
    });
}

const app = firebase.initializeApp(firebaseConfig);
const authentication = auth.getAuth(app);

auth.signInWithEmailAndPassword(authentication, email, password).then(async (userCredential) => {
    updateData();
}).catch((error) => {
    console.log(error);
});