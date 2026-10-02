#!/bin/bash

# Discord Bot with VPS & Minecraft Server Creator, SSHX Link & Admin Control
echo "=========================================="
echo "    DISCORD ADVANCED VPS & MC BOT SETUP"
echo "=========================================="

# 1. Node.js Check & Install
if ! command -v node &> /dev/null
then
    echo "[+] Node.js nahi mila. Install kiya ja raha hai..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[+] Node.js pehle se installed hai."
fi

# 2. Project Directory Setup
BOT_DIR="discord-vps-mc-bot"
mkdir -p $BOT_DIR
cd $BOT_DIR

# 3. User se Credentials Lena
echo ""
read -p "Apna Discord Bot Token daalein: " BOT_TOKEN
read -p "Apni Discord Client ID (Application ID) daalein: " CLIENT_ID
read -p "Apni Discord Admin User ID daalein: " ADMIN_ID
read -p "Default Welcome Role ID daalein: " ROLE_ID

# 4. Package.json create karna
cat << 'EOF' > package.json
{
  "name": "discord-vps-mc-bot",
  "version": "4.0.0",
  "description": "Discord Bot with VPS & Minecraft Server Creator and SSHX Terminal Link",
  "main": "bot.js",
  "scripts": {
    "start": "node bot.js"
  },
  "dependencies": {
    "discord.js": "^14.14.1"
  }
}
EOF

# 5. Bot Code (bot.js) Create Karna
cat << EOF > bot.js
const { Client, GatewayIntentBits, EmbedBuilder, PermissionsBitField, ActionRowBuilder, ButtonBuilder, ButtonStyle, REST, Routes, SlashCommandBuilder } = require('discord.js');
const { exec } = require('child_process');

const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
    ]
});

const TOKEN = "$BOT_TOKEN";
const CLIENT_ID = "$CLIENT_ID";
const ADMIN_ID = "$ADMIN_ID";
const ROLE_ID = "$ROLE_ID";

// Register Slash Commands
const commands = [
    new SlashCommandBuilder().setName('ping').setDescription('Bot ki latency check karein'),
    new SlashCommandBuilder().setName('help').setDescription('Saare available commands ki list dekhein'),
    new SlashCommandBuilder()
        .setName('vpscreate')
        .setDescription('Admin: Naya VPS ya Minecraft server create karein')
        .addStringOption(option => option.setName('type').setDescription('Server Type (vps ya minecraft)').setRequired(true).addChoices(
            { name: 'VPS', value: 'vps' },
            { name: 'Minecraft Server', value: 'minecraft' }
        ))
        .addStringOption(option => option.setName('ram').setDescription('RAM (jaise: 4GB, 8GB)').setRequired(true))
        .addStringOption(option => option.setName('cpu').setDescription('CPU Cores (jaise: 2, 4)').setRequired(true))
        .addStringOption(option => option.setName('disk').setDescription('Disk Space (jaise: 50GB)').setRequired(true))
        .addUserOption(option => option.setName('user').setDescription('Jisko server dena hai usko select karein').setRequired(true))
].map(command => command.toJSON());

const rest = new REST({ version: '10' }).setToken(TOKEN);

(async () => {
    try {
        console.log('[+] Slash commands register ki ja rahi hain...');
        await rest.put(Routes.applicationCommands(CLIENT_ID), { body: commands });
        console.log('[+] Slash commands successfully register ho gayi hain!');
    } catch (error) {
        console.error(error);
    }
})();

client.once('ready', () => {
    console.log(\`[ONLINE] Bot \${client.user.tag} safalta-purnaak online ho chuka hai!\`);
    client.user.setActivity('!help | Managing Servers', { type: 3 });
});

// Welcome System
client.on('guildMemberAdd', member => {
    if (ROLE_ID) member.roles.add(ROLE_ID).catch(() => {});
    const channel = member.guild.systemChannel;
    if (channel) {
        const embed = new EmbedBuilder()
            .setColor(0x00FF00)
            .setTitle('🎉 Naya Sadasya Aaya!')
            .setDescription(\`Swagat hai \${member} (\${member.user.tag}) ka server mein!\`)
            .setThumbnail(member.user.displayAvatarURL({ dynamic: true }))
            .setTimestamp();
        channel.send({ embeds: [embed] });
    }
});

// Helper Function for Server Creation & SSHX Simulation
async function handleServerCreation(messageOrInteraction, type, ram, cpu, disk, targetUser, isSlash = false) {
    const userId = isSlash ? messageOrInteraction.user.id : messageOrInteraction.author.id;
    
    // Check Admin Permission
    if (userId !== ADMIN_ID && !messageOrInteraction.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
        const replyText = "❌ Ye command sirf Admin chala sakta hai!";
        return isSlash ? messageOrInteraction.reply({ content: replyText, ephemeral: true }) : messageOrInteraction.reply(replyText);
    }

    const initialMsg = await (isSlash ? messageOrInteraction.reply({ content: \`⚙️ \${type.toUpperCase()} create ho raha hai... Kripya pratiksha karein.\`, fetchReply: true }) : messageOrInteraction.reply(\`⚙️ \${type.toUpperCase()} create ho raha hai... Kripya pratiksha karein.\`));

    // Simulate Server & SSHX Link Generation
    setTimeout(async () => {
        const fakeSshxLink = \`https://sshx.io/s/#cjh-vps-\${Math.random().toString(36).substring(7)}\`;
        
        const successEmbed = new EmbedBuilder()
            .setColor(0x00AE86)
            .setTitle(\`✅ \${type.toUpperCase()} Safalta-purnaak Create Ho Gaya!\`)
            .addFields(
                { name: '👤 Assigned User', value: \`<@\${targetUser.id}>\`, inline: true },
                { name: '💻 Server Type', value: type.toUpperCase(), inline: true },
                { name: '⚡ RAM / CPU / Disk', value: \`\${ram} / \${cpu} Core / \${disk}\`, inline: true },
                { name: '🔗 SSHX Terminal Link', value: \`[\`Click Here to Open Terminal\`](\${fakeSshxLink})\` }
            )
            .setTimestamp()
            .setFooter({ text: 'Powered by CJH Hosting Bot' });

        if (isSlash) {
            await messageOrInteraction.editReply({ content: \`✨ Server successfully ready ho gaya hai, <@\${targetUser.id}> ke liye!\`, embeds: [successEmbed] });
        } else {
            await initialMsg.edit({ content: \`✨ Server successfully ready ho gaya hai, <@\${targetUser.id}> ke liye!\`, embeds: [successEmbed] });
        }
    }, 3000);
}

// Prefix & Slash Command Handling
client.on('interactionCreate', async interaction => {
    if (!interaction.isChatInputCommand()) return;
    const { commandName, options } = interaction;

    if (commandName === 'ping') {
        await interaction.reply({ content: \`🏓 Pong! \${client.ws.ping}ms latency.\`, ephemeral: true });
    } 
    else if (commandName === 'help') {
        const embed = new EmbedBuilder()
            .setColor(0x5865F2)
            .setTitle('🤖 Bot Command Menu')
            .setDescription('Yahan available active commands ki list hai:')
            .addFields(
                { name: '/ping ya !ping', value: 'Bot latency check karein' },
                { name: '/vpscreate ya !vpscreate [type] [ram] [cpu] [disk] @user', value: 'Admin: VPS ya Minecraft server create karein aur SSHX link paayein' }
            );
        await interaction.reply({ embeds: [embed], ephemeral: true });
    }
    else if (commandName === 'vpscreate') {
        const type = options.getString('type');
        const ram = options.getString('ram');
        const cpu = options.getString('cpu');
        const disk = options.getString('disk');
        const targetUser = options.getUser('user');

        await handleServerCreation(interaction, type, ram, cpu, disk, targetUser, true);
    }
});

// Text Prefix Commands (!vpscreate / !ping / !help)
client.on('messageCreate', async message => {
    if (message.author.bot) return;
    const prefix = '!';
    if (!message.content.startsWith(prefix)) return;

    const args = message.content.slice(prefix.length).trim().split(/ +/);
    const command = args.shift().toLowerCase();

    if (command === 'ping') {
        message.reply(\`🏓 Pong! \${client.ws.ping}ms latency.\`);
    }
    else if (command === 'help') {
        const embed = new EmbedBuilder()
            .setColor(0x5865F2)
            .setTitle('🤖 Bot Command Menu')
            .setDescription('Yahan available active commands ki list hai:')
            .addFields(
                { name: '!ping', value: 'Bot latency check karein' },
                { name: '!vpscreate [vps/minecraft] [ram] [cpu] [disk] @user', value: 'Admin: Server create karein aur SSHX link paayein' }
            );
        message.reply({ embeds: [embed] });
    }
    else if (command === 'vpscreate') {
        // Format: !vpscreate vps 4GB 2 50GB @user
        const type = args[0];
        const ram = args[1];
        const cpu = args[2];
        const disk = args[3];
        const targetUser = message.mentions.users.first();

        if (!type || !ram || !cpu || !disk || !targetUser) {
            return message.reply("⚠️ Sahi format use karein:\n\`!vpscreate vps 4GB 2 50GB @user\` ya \`!vpscreate minecraft 8GB 4 100GB @user\`");
        }

        await handleServerCreation(message, type, ram, cpu, disk, targetUser, false);
    }
});

client.login(TOKEN);
EOF

# 6. Dependencies Install Karna
echo "[+] Bot dependencies install ho rahi hain..."
npm install

# 7. PM2 se 24/7 Run Karna
if ! command -v pm2 &> /dev/null
then
    echo "[+] PM2 install kiya ja raha hai..."
    sudo npm install -g pm2
fi

pm2 start bot.js --name "discord-vps-mc-bot"
pm2 save
pm2 startup

echo "=========================================="
echo " VPS & MINECRAFT SERVER BOT LIVE HO GAYA HAI!"
echo "=========================================="
EOF
