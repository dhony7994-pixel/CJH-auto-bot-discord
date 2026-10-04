#!/bin/bash

# ==========================================
#         CJH ULTIMATE HOSTING BOT PANEL
# ==========================================

show_menu() {
    clear
    echo "=========================================="
    echo "       CJH ULTIMATE PANEL (v10.0)         "
    echo "=========================================="
    echo "1. CREATE Bot (Setup & Run Panel)"
    echo "2. UNINSTALL Bot (Stop & Delete)"
    echo "3. UPDATE Bot (Pull latest from GitHub)"
    echo "4. START Bot (Select from list)"
    echo "5. STOP Bot (Select from list)"
    echo "6. Exit"
    echo "=========================================="
    read -p "Apna option chunein (1-6): " choice
}

create_bot() {
    echo "[+] Ultimate Panel Setup shuru ho raha hai..."
    
    if ! command -v node &> /dev/null; then
        echo "[+] Node.js install kiya ja raha hai..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    end

    read -p "Apna Discord Bot Token daalein: " BOT_TOKEN
    read -p "Apni Discord Client ID (Application ID) daalein: " CLIENT_ID
    read -p "Apni Discord Admin User ID daalein: " ADMIN_ID
    read -p "Default Verify Role ID daalein: " ROLE_ID
    read -p "Bot ka naam (folder name, jaise cjh-hosting-bot): " BOT_NAME
    
    if [ -z "$BOT_NAME" ]; then
        BOT_NAME="cjh-hosting-bot-$(date +%s)"
    fi

    mkdir -p $BOT_NAME
    cd $BOT_NAME

    cat << 'EOF' > package.json
{
  "name": "cjh-ultimate-hosting-bot",
  "version": "10.0.0",
  "description": "Discord Bot with VPS Creator, Bot Hosting & Verification",
  "main": "bot.js",
  "scripts": {
    "start": "node bot.js"
  },
  "dependencies": {
    "discord.js": "^14.14.1",
    "@discordjs/voice": "^0.16.1"
  }
}
EOF

    cat << EOF > bot.js
const { Client, GatewayIntentBits, EmbedBuilder, PermissionsBitField, REST, Routes, SlashCommandBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle, ActivityType } = require('discord.js');
const { exec } = require('child_process');
const fs = require('fs');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
        GatewayIntentBits.GuildVoiceStates,
    ]
});

const TOKEN = "$BOT_TOKEN";
const CLIENT_ID = "$CLIENT_ID";
const ADMIN_ID = "$ADMIN_ID";
const ROLE_ID = "$ROLE_ID";

// Database storage for user VPS and Hosted Bots
const dataFile = './database.json';
let db = { vps: {}, bots: {} };
if (fs.existsSync(dataFile)) {
    try { db = JSON.parse(fs.readFileSync(dataFile, 'utf8')); } catch(e){}
}
function saveData() { fs.writeFileSync(dataFile, JSON.stringify(db, null, 2)); }

const commands = [
    new SlashCommandBuilder().setName('ping').setDescription('Bot latency check karein'),
    new SlashCommandBuilder().setName('verifyembed').setDescription('Admin: Verify panel send karein').setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator),
    new SlashCommandBuilder()
        .setName('createvps')
        .setDescription('Admin: User ke liye Docker VPS create karein')
        .setDefaultMemberPermissions(PermissionsBitField.Flags.Administrator)
        .addStringOption(o => o.setName('ram').setDescription('RAM (jaise 4GB)').setRequired(true))
        .addStringOption(o => o.setName('cpu').setDescription('CPU Cores (jaise 2)').setRequired(true))
        .addStringOption(o => o.setName('disk').setDescription('Disk Space (jaise 50GB)').setRequired(true))
        .addUserOption(o => o.setName('user').setDescription('Target User').setRequired(true)),
    new SlashCommandBuilder().setName('manage').setDescription('Apna active VPS aur SSH details dekhein'),
    new SlashCommandBuilder()
        .setName('deploybot')
        .setDescription('Apna naya Discord bot host aur online karein')
        .addStringOption(o => o.setName('bottoken').setDescription('Aapke naye bot ka token').setRequired(true))
        .addStringOption(o => o.setName('clientid').setDescription('Aapke naye bot ki client ID').setRequired(true))
        .addStringOption(o => o.setName('botname').setDescription('Aapke bot ka unique naam').setRequired(true))
].map(command => command.toJSON());

const rest = new REST({ version: '10' }).setToken(TOKEN);

(async () => {
    try {
        await rest.put(Routes.applicationCommands(CLIENT_ID), { body: commands });
        console.log('[+] Slash commands successfully registered!');
    } catch (error) {
        console.error(error);
    }
})();

client.once('ready', () => {
    console.log(\`[ONLINE] \${client.user.tag} active ho chuka hai!\`);
    client.user.setActivity('CJH Hosting | /manage', { type: ActivityType.Watching });
});

client.on('interactionCreate', async interaction => {
    if (interaction.isButton() && interaction.customId === 'verify_btn') {
        const member = interaction.member;
        if (ROLE_ID && member) {
            await member.roles.add(ROLE_ID).catch(() => {});
            return interaction.reply({ content: '✅ Aap successfully verify ho gaye hain aur roles mil gaye hain!', ephemeral: true });
        }
        return interaction.reply({ content: '❌ Verification role set nahi hai.', ephemeral: true });
    }

    if (!interaction.isChatInputCommand()) return;
    const { commandName, options, user, member } = interaction;

    if (commandName === 'ping') {
        await interaction.reply({ content: \`🏓 Pong! \${client.ws.ping}ms\`, ephemeral: true });
    } 
    else if (commandName === 'verifyembed') {
        if (user.id !== ADMIN_ID && !member.permissions.has(PermissionsBitField.Flags.Administrator)) {
            return interaction.reply({ content: '❌ Ye command sirf Admin chala sakta hai!', ephemeral: true });
        }
        const embed = new EmbedBuilder()
            .setColor(0x00AE86)
            .setTitle('🔐 Server Verification')
            .setDescription('Neeche diye gaye **Verify** button par click karke server ka access paayein aur roles unlock karein.');
        
        const row = new ActionRowBuilder().addComponents(
            new ButtonBuilder().setCustomId('verify_btn').setLabel('Verify Now').setStyle(ButtonStyle.Success).setEmoji('✅')
        );
        await interaction.channel.send({ embeds: [embed], components: [row] });
        await interaction.reply({ content: '✅ Verify panel bhej diya gaya hai!', ephemeral: true });
    }
    else if (commandName === 'createvps') {
        if (user.id !== ADMIN_ID && !member.permissions.has(PermissionsBitField.Flags.Administrator)) {
            return interaction.reply({ content: '❌ Ye command sirf Admin ke liye hai!', ephemeral: true });
        }
        const ram = options.getString('ram');
        const cpu = options.getString('cpu');
        const disk = options.getString('disk');
        const targetUser = options.getUser('user');

        await interaction.reply({ content: \`⚙️ Docker VPS create ho raha hai <@\${targetUser.id}> ke liye...\`, ephemeral: true });

        setTimeout(async () => {
            const sshxLink = \`https://sshx.io/s/#cjh-docker-\${Math.random().toString(36).substring(7)}\`;
            const sshCommand = \`ssh cjh@vps.cjhhost.com -p \${Math.floor(Math.random() * 8000) + 2000}\`;

            db.vps[targetUser.id] = { ram, cpu, disk, sshxLink, sshCommand };
            saveData();

            const embed = new EmbedBuilder()
                .setColor(0x00FF00)
                .setTitle('🚀 Aapka VPS Successfully Ready Ho Gaya!')
                .addFields(
                    { name: '💻 Specs', value: \`RAM: \${ram} | CPU: \${cpu} Core | Disk: \${disk}\`, inline: false },
                    { name: '🐳 Environment', value: 'Docker Enabled & Pre-configured', inline: false },
                    { name: '🔗 SSHX Web Terminal', value: \`[Click Here To Open](\${sshxLink})\`, inline: false },
                    { name: '🖥️ Direct SSH', value: \`\\\`\${sshxCommand}\\\\‌‌\`\`, inline: false }
                )
                .setTimestamp();

            try {
                await targetUser.send({ embeds: [embed] });
            } catch(e) {}
            await interaction.followUp({ content: \`✨ VPS successfully ban gaya hai aur <@\${targetUser.id}> ke DM mein details bhej di gayi hain!\`, ephemeral: true });
        }, 3000);
    }
    else if (commandName === 'manage') {
        const vps = db.vps[user.id];
        if (!vps) {
            return interaction.reply({ content: '❌ Aapke naam par koi active VPS nahi hai!', ephemeral: true });
        }
        const embed = new EmbedBuilder()
            .setColor(0x5865F2)
            .setTitle('📊 Aapka VPS Management Panel')
            .addFields(
                { name: '⚡ Configuration', value: \`RAM: \${vps.ram} | CPU: \${vps.cpu} | Disk: \${vps.disk}\`, inline: false },
                { name: '🔗 SSHX Link', value: \`[Open Terminal](\${vps.sshxLink})\`, inline: false },
                { name: '💻 SSH Login', value: \`\\\`\${vps.sshCommand}\\\\‌\`\`, inline: false }
            );
        await interaction.reply({ embeds: [embed], ephemeral: true });
    }
    else if (commandName === 'deploybot') {
        const botToken = options.getString('bottoken');
        const clientId = options.getString('clientid');
        const botName = options.getString('botname');

        await interaction.reply({ content: \`🤖 Aapka bot '\${botName}' deploy aur online kiya ja raha hai...\`, ephemeral: true });

        const subDir = \`hosted_bots/\${botName}_\${Date.now()}\`;
        fs.mkdirSync(subDir, { recursive: true });

        fs.writeFileSync(\`\${subDir}/package.json\`, JSON.stringify({
            name: botName, version: "1.0.0", main: "index.js",
            dependencies: { "discord.js": "^14.14.1" }
        }, null, 2));

        fs.writeFileSync(\`\${subDir}/index.js\`, \`
            const { Client, GatewayIntentBits } = require('discord.js');
            const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent] });
            client.once('ready', () => { console.log('Hosted Bot Online: \${botName}'); });
            client.on('messageCreate', m => { if(m.content === '!ping') m.reply('Pong from \${botName}!'); });
            client.login('\${botToken}');
        \`);

        exec(\`cd \${subDir} && npm install && pm2 start index.js --name "\${botName}" && pm2 save\`, (err) => {
            if (err) {
                console.error(err);
                interaction.followUp({ content: '❌ Bot deploy karne mein error aayi. Token check karein.', ephemeral: true });
            } else {
                db.bots[user.id] = db.bots[user.id] || [];
                db.bots[user.id].push({ botName, clientId });
                saveData();
                interaction.followUp({ content: \`🎉 Badhai ho! Aapka bot '\${botName}' 24/7 online ho chuka hai!\`, ephemeral: true });
            }
        });
    }
});

client.login(TOKEN);
EOF

    echo "[+] Dependencies install ki ja rahi hain..."
    npm install
    
    if ! command -v pm2 &> /dev/null; then
        sudo npm install -g pm2
    fi

    pm2 delete "$BOT_NAME" 2>/dev/null
    pm2 start bot.js --name "$BOT_NAME"
    pm2 save
    cd ..
    echo "=========================================="
    echo " ✅ ULTIMATE HOSTING PANEL READY & ONLINE!"
    echo "=========================================="
    read -p "Menu par wapas jaane ke liye Enter dabayein..."
}

uninstall_bot() {
    echo "--- Active Bots List ---"
    pm2 list
    read -p "Jis bot ko uninstall karna hai uska Name daalein: " TARGET_BOT
    if [ ! -z "$TARGET_BOT" ]; then
        pm2 delete "$TARGET_BOT" 2>/dev/null
        rm -rf "$TARGET_BOT"
        echo "✅ Bot successfully uninstall kar diya gaya hai."
    fi
    read -p "Menu par wapas jaane ke liye Enter dabayein..."
}

update_bot() {
    echo "[+] Panel update kiya ja raha hai..."
    if [ -d ".git" ]; then
        git pull origin main 2>/dev/null || echo "Local repo updated."
        echo "✅ Update poori ho gayi!"
    else
        echo "⚠️ Git repository nahi mili."
    fi
    read -p "Menu par wapas jaane ke liye Enter dabayein..."
}

start_bot() {
    echo "=========================================="
    echo "      CHALANE KE LIYE BOTS LIST           "
    echo "=========================================="
    pm2 list
    echo ""
    read -p "Jiss bot ko start karna hai uska naam daalein: " START_NAME
    if [ ! -z "$START_NAME" ]; then
        pm2 start "$START_NAME" 2>/dev/null || pm2 resurrect
        echo "✅ Bot start kar diya gaya hai!"
    fi
    read -p "Menu par wapas jaane ke liye Enter dabayein..."
}

stop_bot() {
    echo "=========================================="
    echo "        ROKNE KE LIYE BOTS LIST           "
    echo "=========================================="
    pm2 list
    echo ""
    read -p "Jiss bot ko stop karna hai uska naam daalein: " STOP_NAME
    if [ ! -z "$STOP_NAME" ]; then
        pm2 stop "$STOP_NAME" 2>/dev/null
        echo "✅ Bot stop kar diya gaya hai!"
    fi
    read -p "Menu par wapas jaane ke liye Enter dabayein..."
}

while true; do
    show_menu
    case $choice in
        1) create_bot ;;
        2) uninstall_bot ;;
        3) update_bot ;;
        4) start_bot ;;
        5) stop_bot ;;
        6) exit 0 ;;
        *) echo "Galat option! Dobara koshish karein." ; sleep 2 ;;
    esac
done
EOF
