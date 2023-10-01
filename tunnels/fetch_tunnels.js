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

fs.writeFileSync("/Users/amitrai/Projects/Friday/codebase/sentinel-client/javascript.txt", "tunnels", 'utf8');

function fetchData() {
    const db = database.getDatabase(app);
    const dbRefPath = dbBasePath + "/" + env + "/" + (envType ? envType + "/" : "");
    const sentinelRecordsRef = database.ref(db, dbRefPath);

    database.onValue(sentinelRecordsRef, (snapshot, err) => {
        if(err) {
            console.log(err);
        }
        const fileName = basePath + '/tunnels/' + env + (envType ? '.' + envType : '') + '.json';
        const updatedURIObj = Object.assign({}, snapshot.val());
        const tunnels = JSON.stringify(updatedURIObj?.specs?.public_tunnels);
        fs.writeFileSync(fileName, tunnels, 'utf8');
        process.exit(0);
    });
}

const app = firebase.initializeApp(firebaseConfig);
const authentication = auth.getAuth(app);

auth.signInWithEmailAndPassword(authentication, email, password).then(async (userCredential) => {
    fetchData();
}).catch((error) => {
    console.log(error);
});