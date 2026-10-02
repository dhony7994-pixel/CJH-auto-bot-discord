#!/bin/bash

# Discord Bot All-in-One Setup Script for VPS
# Ye script Node.js, bot code, aur configuration ko automate karegi.

echo "=========================================="
echo "    DISCORD BOT AUTO-INSTALLER VPS"
echo "=========================================="

# 1. Node.js check & install
if ! command -v node &> /dev/null
then
    echo "[+] Node.js nahi mila. Install kiya ja raha hai..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[+] Node.js pehle se installed hai."
fi

# 2. Project Directory Setup
BOT_DIR="discord-ultimate-bot"
mkdir -p $BOT_DIR
cd $BOT_DIR

# 3. User se Credentials Lena
echo ""
read -p "Apna Discord Bot Token daalein: " BOT_TOKEN
read -p "Apni Discord Admin User ID daalein: " ADMIN_ID
read -p "Default User Role ID daalein (jise join hone par role mile): " ROLE_ID

# 4. Package.json create karna
cat << 'EOF' > package.json
{
  "name": "discord-ultimate-bot",
  "version": "1.0.0",
  "description": "All-in-one feature rich Discord bot",
  "main": "bot.js",
  "scripts": {
    "start": "node bot.js"
  },
  "dependencies": {
    "discord.js": "^14.14.1"
  }
}
EOF

# 5. Bot Code (bot.js) Create Karna (Sare Features ke sath)
cat << EOF > bot.js
const { Client, GatewayIntentBits, EmbedBuilder, PermissionsBitField } = require('discord.js');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
    ]
});

const TOKEN = "$BOT_TOKEN";
const ADMIN_ID = "$ADMIN_ID";
const ROLE_ID = "$ROLE_ID";

client.once('ready', () => {
    printBanner();
    console.log(\`[ONLINE] Bot \${client.user.tag} safalta-purnaak online ho chuka hai!\`);
    client.user.setActivity('!help | Moderation & Fun', { type: 3 });
});

// Auto-Role on Member Join
client.on('guildMemberAdd', member => {
    if (ROLE_ID && ROLE_ID !== "") {
        member.roles.add(ROLE_ID).catch(console.error);
    }
    const welcomeEmbed = new EmbedBuilder()
        .setColor(0x00FF00)
        .setTitle('Naya Sadasya Aaya!')
        .setDescription(\`Swagat hai \${member} server mein! Apne doston ko bhi invite karein.\`)
        .setTimestamp();
    
    const channel = member.guild.systemChannel;
    if (channel) channel.send({ embeds: [welcomeEmbed] });
});

// Advanced Commands Logic
client.on('messageCreate', async message => {
    if (message.author.bot) return;
    const prefix = '!';
    if (!message.content.startsWith(prefix)) return;

    const args = message.content.slice(prefix.length).trim().split(/ +/);
    const command = args.shift().toLowerCase();

    // 1. Help Command
    if (command === 'help') {
        const helpEmbed = new EmbedBuilder()
            .setColor(0x5865F2)
            .setTitle('🤖 Bot Command Menu')
            .setDescription('Yahan saare available commands ki list hai:')
            .addFields(
                { name: '!ping', value: 'Bot ki latency check karne ke liye.' },
                { name: '!serverinfo', value: 'Server ki details dekhne ke liye.' },
                { name: '!userinfo @user', value: 'Kisi bhi user ki profile info ke liye.' },
                { name: '!kick @user [reason]', value: 'Server se member ko kick karne ke liye (Admin).' },
                { name: '!ban @user [reason]', value: 'Server se member ko ban karne ke liye (Admin).' },
                { name: '!clear [1-100]', value: 'Chat messages delete karne ke liye (Admin).' },
                { name: '!say [message]', value: 'Bot se kuch bhi bulwane ke liye.' }
            )
            .setTimestamp();
        message.reply({ embeds: [helpEmbed] });
    }

    // 2. Ping Command
    else if (command === 'ping') {
        message.reply(\`Pong! \${client.ws.ping}ms latency hai.\`);
    }

    // 3. Server Info Command
    else if (command === 'serverinfo') {
        const sEmbed = new EmbedBuilder()
            .setColor(0xF1C40F)
            .setTitle(message.guild.name)
            .addFields(
                { name: 'Total Members', value: \`\${message.guild.memberCount}\`, inline: true },
                { name: 'Created On', value: \`\${message.guild.createdAt.toDateString()}\`, inline: true }
            );
        message.reply({ embeds: [sEmbed] });
    }

    // 4. Clear / Purge Command
    else if (command === 'clear') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.ManageMessages)) {
            return message.reply("Aapke paas messages delete karne ki permission nahi hai!");
        }
        let count = parseInt(args[0]);
        if (!count || count < 1 || count > 100) return message.reply("Kripya 1 se 100 ke beech ki sankhya dein!");
        await message.channel.bulkDelete(count, true).catch(err => message.reply("Purane messages delete nahi ho sakte!"));
        message.channel.send(\`\${count} messages delete kar diye gaye.\`).then(msg => setTimeout(() => msg.delete(), 3000));
    }

    // 5. Kick Command
    else if (command === 'kick') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.KickMembers)) {
            return message.reply("Aapke paas kick karne ki permission nahi hai!");
        }
        const member = message.mentions.members.first();
        if (!member) return message.reply("Kripya kisi member ko mention karein!");
        await member.kick().catch(() => message.reply("Main is member ko kick nahi kar saka!"));
        message.reply(\`\${member.user.tag} ko server se kick kar diya gaya.\`);
    }

    // 6. Ban Command
    else if (command === 'ban') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.BanMembers)) {
            return message.reply("Aapke paas ban karne ki permission nahi hai!");
        }
        const member = message.mentions.members.first();
        if (!member) return message.reply("Kripya kisi member ko mention karein!");
        await member.ban().catch(() => message.reply("Main is member ko ban nahi kar saka!"));
        message.reply(\`\${member.user.tag} ko ban kar diya gaya.\`);
    }

    // 7. Say Command
    else if (command === 'say') {
        if (message.author.id !== ADMIN_ID) return message.reply("Ye command sirf Admin chala sakta hai!");
        const text = args.join(' ');
        if (!text) return message.reply("Kripya message likhein jo bot bole.");
        message.delete().catch(() => {});
        message.channel.send(text);
    }
});

function printBanner() {
    console.log("------------------------------------------");
    console.log(" Bot Successfully Configured & Running!");
    console.log("------------------------------------------");
}

client.login(TOKEN);
EOF

# 6. Dependencies Install Karna
echo "[+] Bot dependencies install ho rahi hain..."
npm install

# 7. PM2 (Process Manager) se Background me 24/7 Run Karna
if ! command -v pm2 &> /dev/null
then
    echo "[+] PM2 install kiya ja raha hai taaki bot background me 24/7 chale..."
    sudo npm install -g pm2
fi

echo "[+] Bot ko PM2 ke sath start kiya ja raha hai..."
pm2 start bot.js --name "discord-bot"
pm2 save
pm2 startup

echo "=========================================="
echo " SAARE KAAM PURE HO GAYE! BOT ONLINE HAI."
echo "=========================================="
EOF
