const fs = require("fs").promises;
const { v4: uuidv4 } = require("uuid");
const { compare } = require("bcrypt");
const { config } = require("./dist/config-manager");
const { connect } = require("./dist/database");
const { PNID } = require("./dist/models/pnid");
const { nintendoPasswordHash } = require("./dist/util");

// See https://github.com/GabIsAwesome/accountfile-generator and
// https://github.com/PretendoNetwork/website/blob/99ee7ebe0aa1c2b632526f1de42f9f8b0d15940d/src/routes/account.js#L245-L284

async function runAsync() {
    if (process.argv.length < 4) {
        console.log("Usage: <pnid-username> <password> <persistent-id>");
        process.exit(1);
    }

    await connect();

    const pnid = await PNID.findOne({
        usernameLower: process.argv[1].toLowerCase(),
    });
    if (pnid) {
        const accountDat = await generateAccountDat(pnid, process.argv[2], process.argv[3]);
        await fs.writeFile(`/tmp/account.dat`, accountDat);
    } else {
        throw new Error(`No PNID found for username ${process.argv[1]}.`);
    }
}

runAsync().then(() => {
    process.exit(0);
});

async function generateAccountDat(pnid, password, persistentId) {
    const hashedPassword = nintendoPasswordHash(password, pnid.pid);
    let accountDat = "AccountInstance_00000000\n";
    accountDat += `PersistentId=${persistentId}\n`;
    accountDat += "TransferableIdBase=0\n";
    accountDat += `Uuid=${uuidv4().replace(/-/g, "")}\n`;
    accountDat += `MiiData=${Buffer.from(pnid.mii.data, "base64").toString("hex")}\n`;
    
    const miiNameBuffer = Buffer.alloc(0x16);
    const miiName = Buffer.from(pnid.mii.name, 'utf16le').swap16();
    miiName.copy(miiNameBuffer);
    accountDat += `MiiName=${miiNameBuffer.toString("hex")}\n`;
    
    accountDat += `AccountId=${pnid.username}\n`;
    accountDat += "BirthYear=0\n";
    accountDat += "BirthMonth=0\n";
    accountDat += "BirthDay=0\n";
    accountDat += "Gender=0\n";
    accountDat += `EmailAddress=${pnid.email.address}\n`;
    accountDat += "Country=0\n";
    accountDat += "SimpleAddressId=0\n";
    accountDat += `PrincipalId=${pnid.pid.toString(16)}\n`;
    accountDat += "IsPasswordCacheEnabled=1\n";
    accountDat += `AccountPasswordCache=${hashedPassword}`;

    return accountDat;
}
