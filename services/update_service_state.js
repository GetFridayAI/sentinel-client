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

const fileName = basePath + '/services/' + env + (envType ? '.' + envType : '') + '.json';
const services = JSON.parse(fs.readFileSync(fileName, { encoding: 'utf8', flag: 'r' }));
const areAllServicesUp = Object.keys(services).filter((service) => { return services[service]['current_state'] === 0 }).length === 0;

if (areAllServicesUp) fs.rmSync(fileName);

function updateData() {
    const db = database.getDatabase(app);
    const dbRefPath = dbBasePath + "/" + env + "/" + (envType ? envType + "/" : "");
    const sentinelRecordsRef = database.ref(db, dbRefPath);

    database.onValue(sentinelRecordsRef, (snapshot, err) => {
        if(err) {
            console.log(err);
        }
        const dbSnapshot = Object.assign({}, snapshot.val());
        let modifiedDbSnapshot = {};
        
        if (!dbSnapshot.performance) {
            dbSnapshot.performance = {};
        }
        
        if (!dbSnapshot.performance.services) {
            dbSnapshot.performance.services = {
                jenkins: [],
                nginx: [],
                neo4j: []
            }
        } else {
            if (!dbSnapshot.performance.services.jenkins) {
                dbSnapshot.performance.services.jenkins = [];
            }

            if (!dbSnapshot.performance.services.neo4j) {
                dbSnapshot.performance.services.neo4j = [];
            }

            if (!dbSnapshot.performance.services.nginx) {
                dbSnapshot.performance.services.nginx = [];
            }
        }

        Object.keys(services).map((service) => {
            const isTunnelRunning = services[service]['current_state'] === 1;
            const log = {
                timestamp: services[service]['timestamp'],
                data: {
                    isRunning: isTunnelRunning.toString(),
                    errorMessage: services[service]['errorMessage'] ? services[service]['errorMessage'] : 'null'
                }
            }
            dbSnapshot.performance.services[service].push(log);
        });

        modifiedDbSnapshot[dbRefPath] = dbSnapshot;
        database.update(database.ref(db), modifiedDbSnapshot).then(() => {
            process.exit(0);
        }).catch((error) => {
            console.log(error);
            process.exit(0);
        });
    }, {
        onlyOnce: true
    });
}

const app = firebase.initializeApp(firebaseConfig);
const authentication = auth.getAuth(app);

auth.signInWithEmailAndPassword(authentication, email, password).then(async (userCredential) => {
    updateData();
}).catch((error) => {
    console.log(error);
});