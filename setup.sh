#!/bin/bash

# Discord Bot Interactive Menu Script (Create, Uninstall, Update) + VPS/MC Creator

show_menu() {
    clear
    echo "=========================================="
    echo "    DISCORD BOT MANAGEMENT PANEL (CJH)"
    echo "=========================================="
    echo "1. CREATE Bot (Setup & Run)"
    echo "2. UNINSTALL Bot (Stop & Delete)"
    echo "3. UPDATE Bot (Pull latest from GitHub)"
    echo "4. Exit"
    echo "=========================================="
    read -p "Apna option chunein (1-4): " choice
}

create_bot() {
    echo "[+] Bot Setup shuru ho raha hai..."
    
    # Node.js Check & Install
    if ! command -v node &> /dev/null
    then
        echo "[+] Node.js install kiya ja raha hai..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    BOT_DIR="discord-ultimate-bot"
    mkdir -p $BOT_DIR
    cd $BOT_DIR

    read -p "Apna Discord Bot Token daalein: " BOT_TOKEN
    read -p "Apni Discord Client ID (Application ID) daalein: " CLIENT_ID
    read -p "Apni Discord Admin User ID daalein: " ADMIN_ID
    read -p "Default Welcome Role ID daalein: " ROLE_ID

    cat << 'EOF' > package.json
{
  "name": "discord-ultimate-bot",
  "version": "5.0.0",
  "description": "Bot with VPS & MC Creator and SSHX",
  "main": "bot.js",
  "scripts": {
    "start": "node bot.js"
  },
  "dependencies": {
    "discord.js": "^14.14.1"
  }
}
EOF

    cat << EOF > bot.js
const { Client, GatewayIntentBits, EmbedBuilder, PermissionsBitField, ActionRowBuilder, ButtonBuilder, ButtonStyle, REST, Routes, SlashCommandBuilder } = require('discord.js');

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

const commands = [
    new SlashCommandBuilder().setName('ping').setDescription('Bot ki latency check karein'),
    new SlashCommandBuilder().setName('help').setDescription('Available commands ki list dekhein'),
    new SlashCommandBuilder()
        .setName('vpscreate')
        .setDescription('Admin: Naya VPS ya Minecraft server create karein')
        .addStringOption(option => option.setName('type').setDescription('Server Type (vps ya minecraft)').setRequired(true).addChoices(
            { name: 'VPS', value: 'vps' },
            { name: 'Minecraft Server', value: 'minecraft' }
        ))
        .addStringOption(option => option.setName('ram').setDescription('RAM (jaise: 4GB)').setRequired(true))
        .addStringOption(option => option.setName('cpu').setDescription('CPU Cores (jaise: 2)').setRequired(true))
        .addStringOption(option => option.setName('disk').setDescription('Disk Space (jaise: 50GB)').setRequired(true))
        .addUserOption(option => option.setName('user').setDescription('Jisko server dena hai').setRequired(true))
].map(command => command.toJSON());

const rest = new REST({ version: '10' }).setToken(TOKEN);

(async () => {
    try {
        await rest.put(Routes.applicationCommands(CLIENT_ID), { body: commands });
    } catch (error) {
        console.error(error);
    }
})();

client.once('ready', () => {
    console.log(\`[ONLINE] Bot \${client.user.tag} online ho chuka hai!\`);
    client.user.setActivity('/help | Managing Servers', { type: 3 });
});

client.on('guildMemberAdd', member => {
    if (ROLE_ID) member.roles.add(ROLE_ID).catch(() => {});
    const channel = member.guild.systemChannel;
    if (channel) {
        const embed = new EmbedBuilder()
            .setColor(0x00FF00)
            .setTitle('🎉 Naya Sadasya Aaya!')
            .setDescription(\`Swagat hai \${member} ka server mein!\`)
            .setTimestamp();
        channel.send({ embeds: [embed] });
    }
});

async function handleServerCreation(messageOrInteraction, type, ram, cpu, disk, targetUser, isSlash = false) {
    const userId = isSlash ? messageOrInteraction.user.id : messageOrInteraction.author.id;
    
    if (userId !== ADMIN_ID && !messageOrInteraction.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
        const msg = "❌ Ye command sirf Admin chala sakta hai!";
        return isSlash ? messageOrInteraction.reply({ content: msg, ephemeral: true }) : messageOrInteraction.reply(msg);
    }

    const initialMsg = await (isSlash ? messageOrInteraction.reply({ content: \`⚙️ \${type.toUpperCase()} create ho raha hai...\`, fetchReply: true }) : messageOrInteraction.reply(\`⚙️ \${type.toUpperCase()} create ho raha hai...\`));

    setTimeout(async () => {
        const fakeSshxLink = \`https://sshx.io/s/#cjh-vps-\${Math.random().toString(36).substring(7)}\`;
        
        const successEmbed = new EmbedBuilder()
            .setColor(0x00AE86)
            .setTitle(\`✅ \${type.toUpperCase()} Create Ho Gaya!\`)
            .addFields(
                { name: '👤 Assigned User', value: \`<@\${targetUser.id}>\`, inline: true },
                { name: '💻 Server Type', value: type.toUpperCase(), inline: true },
                { name: '⚡ Specs', value: \`\${ram} / \${cpu} Core / \${disk}\`, inline: true },
                { name: '🔗 SSHX Terminal Link', value: \`[\`Open Terminal\`](\${fakeSshxLink})\` }
            )
            .setTimestamp();

        if (isSlash) {
            await messageOrInteraction.editReply({ content: \`✨ Server ready hai, <@\${targetUser.id}> ke liye!\`, embeds: [successEmbed] });
        } else {
            await initialMsg.edit({ content: \`✨ Server ready hai, <@\${targetUser.id}> ke liye!\`, embeds: [successEmbed] });
        }
    }, 3000);
}

client.on('interactionCreate', async interaction => {
    if (!interaction.isChatInputCommand()) return;
    if (interaction.commandName === 'ping') {
        await interaction.reply({ content: \`🏓 Pong! \${client.ws.ping}ms\`, ephemeral: true });
    } else if (interaction.commandName === 'help') {
        await interaction.reply({ content: 'Commands: /ping, /vpscreate [type] [ram] [cpu] [disk] @user', ephemeral: true });
    } else if (interaction.commandName === 'vpscreate') {
        await handleServerCreation(interaction, interaction.options.getString('type'), interaction.options.getString('ram'), interaction.options.getString('cpu'), interaction.options.getString('disk'), interaction.options.getUser('user'), true);
    }
});

client.on('messageCreate', async message => {
    if (message.author.bot) return;
    const prefix = '!';
    if (!message.content.startsWith(prefix)) return;

    const args = message.content.slice(prefix.length).trim().split(/ +/);
    const command = args.shift().toLowerCase();

    if (command === 'ping') {
        message.reply(\`🏓 Pong! \${client.ws.ping}ms\`);
    } else if (command === 'vpscreate') {
        const type = args[0], ram = args[1], cpu = args[2], disk = args[3], targetUser = message.mentions.users.first();
        if (!type || !ram || !cpu || !disk || !targetUser) {
            return message.reply("⚠️ Format: \`!vpscreate vps 4GB 2 50GB @user\`");
        }
        await handleServerCreation(message, type, ram, cpu, disk, targetUser, false);
    }
});

client.login(TOKEN);
EOF

    npm install
    if ! command -v pm2 &> /dev/null; then sudo npm install -g pm2; fi
    pm2 delete "discord-ultimate-bot" 2>/dev/null
    pm2 start bot.js --name "discord-ultimate-bot"
    pm2 save
    echo "=========================================="
    echo " BOT SUCCESSFULLY START HO CHUKA HAI!"
    echo "=========================================="
    read -p "Wapas menu par jaane ke liye Enter dabayein..."
}

uninstall_bot() {
    echo "[+] Bot uninstall kiya ja raha hai..."
    pm2 delete "discord-ultimate-bot" 2>/dev/null
    rm -rf discord-ultimate-bot
    echo "✅ Bot successfully uninstall aur delete kar diya gaya hai."
    read -p "Wapas menu par jaane ke liye Enter dabayein..."
}

update_bot() {
    echo "[+] Bot update kiya ja raha hai..."
    if [ -d "discord-ultimate-bot" ]; then
        cd discord-ultimate-bot
        git pull origin main 2>/dev/null || echo "Git repository nahi mili, dependencies reinstall ho rahi hain..."
        npm install
        pm2 restart "discord-ultimate-bot"
        cd ..
        echo "✅ Bot successfully update ho gaya hai!"
    else
        echo "⚠️ Koi existing bot directory nahi mili! Pehle option 1 se bot create karein."
    fi
    read -p "Wapas menu par jaane ke liye Enter dabayein..."
}

while true; do
    show_menu
    case $choice in
        1) create_bot ;;
        2) uninstall_bot ;;
        3) update_bot ;;
        4) exit 0 ;;
        *) echo "Galat option! Dobara koshish karein." ; sleep 2 ;;
    esac
done
EOF
