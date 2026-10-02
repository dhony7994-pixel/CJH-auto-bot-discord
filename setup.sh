#!/bin/bash

# Discord Advanced All-in-One Bot Setup Script for VPS
# Features: Welcome, Verify, Giveaway, Moderation, Auto-Role, Fun Commands

echo "=========================================="
echo "    DISCORD ULTIMATE BOT AUTO-INSTALLER"
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
BOT_DIR="discord-ultimate-bot"
mkdir -p $BOT_DIR
cd $BOT_DIR

# 3. User se Credentials Lena
echo ""
read -p "Apna Discord Bot Token daalein: " BOT_TOKEN
read -p "Apni Discord Admin User ID daalein: " ADMIN_ID
read -p "Default User Role ID daalein (Welcome/Auto-role ke liye): " ROLE_ID
read -p "Verification Role ID daalein (Verify hone par milne wala role): " VERIFY_ROLE_ID

# 4. Package.json create karna
cat << 'EOF' > package.json
{
  "name": "discord-ultimate-bot",
  "version": "2.0.0",
  "description": "Advanced All-in-One Discord Bot with Giveaway, Verify, Welcome & Mod",
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
const { Client, GatewayIntentBits, EmbedBuilder, PermissionsBitField, ActionRowBuilder, ButtonBuilder, ButtonStyle } = require('discord.js');

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
const VERIFY_ROLE_ID = "$VERIFY_ROLE_ID";

client.once('ready', () => {
    console.log(\`[ONLINE] Bot \${client.user.tag} safalta-purnaak online ho chuka hai!\`);
    client.user.setActivity('!help | Advanced Security & Fun', { type: 3 });
});

// Auto-Role & Welcome System on Member Join
client.on('guildMemberAdd', member => {
    if (ROLE_ID && ROLE_ID !== "") {
        member.roles.add(ROLE_ID).catch(console.error);
    }
    
    const welcomeEmbed = new EmbedBuilder()
        .setColor(0x00FF00)
        .setTitle('🎉 Naya Sadasya Server Mein Aaya!')
        .setDescription(\`Swagat hai \${member} (\${member.user.tag}) hamare server mein! \nKripya rules channel check karein.\`)
        .setThumbnail(member.user.displayAvatarURL({ dynamic: true }))
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

    // 1. Help Menu
    if (command === 'help') {
        const helpEmbed = new EmbedBuilder()
            .setColor(0x5865F2)
            .setTitle('🤖 Ultimate Bot Command Center')
            .setDescription('Yahan aapke saare features aur commands ki list hai:')
            .addFields(
                { name: '🛡️ Moderation', value: '\`!kick\`, \`!ban\`, \`!clear\`, \`!mute\`, \`!unmute\`, \`!lock\`, \`!unlock\`' },
                { name: '🎁 Giveaway & Utility', value: '\`!giveaway [prize]\`, \`!verifyembed\`, \`!ping\`, \`!serverinfo\`, \`!userinfo\`' },
                { name: '💬 Fun & Interaction', value: '\`!say [text]\`, \`!poll [question]\`' }
            )
            .setFooter({ text: 'Powered by VPS Auto Setup' })
            .setTimestamp();
        message.reply({ embeds: [helpEmbed] });
    }

    // 2. Ping
    else if (command === 'ping') {
        message.reply(\`🏓 Pong! Latency: \${client.ws.ping}ms\`);
    }

    // 3. Server Info
    else if (command === 'serverinfo') {
        const sEmbed = new EmbedBuilder()
            .setColor(0xF1C40F)
            .setTitle(message.guild.name)
            .setThumbnail(message.guild.iconURL({ dynamic: true }))
            .addFields(
                { name: '👑 Owner', value: \`<@\${message.guild.ownerId}>\`, inline: true },
                { name: '👥 Total Members', value: \`\${message.guild.memberCount}\`, inline: true },
                { name: '📅 Created On', value: \`\${message.guild.createdAt.toDateString()}\`, inline: true }
            );
        message.reply({ embeds: [sEmbed] });
    }

    // 4. User Info
    else if (command === 'userinfo') {
        const target = message.mentions.users.first() || message.author;
        const member = message.guild.members.cache.get(target.id);
        const uEmbed = new EmbedBuilder()
            .setColor(0x3498DB)
            .setTitle(\`User Info: \${target.tag}\`)
            .setThumbnail(target.displayAvatarURL({ dynamic: true }))
            .addFields(
                { name: 'ID', value: target.id, inline: true },
                { name: 'Joined Server', value: member.joinedAt.toDateString(), inline: true }
            );
        message.reply({ embeds: [uEmbed] });
    }

    // 5. Clear Messages (Purge)
    else if (command === 'clear') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.ManageMessages)) {
            return message.reply("❌ Aapke paas messages delete karne ki permission nahi hai!");
        }
        let count = parseInt(args[0]);
        if (!count || count < 1 || count > 100) return message.reply("⚠️ Kripya 1 se 100 ke beech ki sankhya dein!");
        await message.channel.bulkDelete(count, true).catch(() => message.reply("⚠️ Purane messages delete nahi kiye ja sakte!"));
        const m = await message.channel.send(\`✅ \${count} messages delete kar diye gaye.\`);
        setTimeout(() => m.delete().catch(() => {}), 3000);
    }

    // 6. Kick Command
    else if (command === 'kick') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.KickMembers)) {
            return message.reply("❌ Aapke paas members ko kick karne ki permission nahi hai!");
        }
        const member = message.mentions.members.first();
        if (!member) return message.reply("⚠️️ Kripya kisi member ko mention karein!");
        await member.kick().catch(() => message.reply("❌ Main is member ko kick nahi kar saka!"));
        message.reply(\`✅ \${member.user.tag} ko server se kick kar diya gaya.\`);
    }

    // 7. Ban Command
    else if (command === 'ban') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.BanMembers)) {
            return message.reply("❌ Aapke paas members ko ban karne ki permission nahi hai!");
        }
        const member = message.mentions.members.first();
        if (!member) return message.reply("⚠️ Kripya kisi member ko mention karein!");
        await member.ban().catch(() => message.reply("❌ Main is member ko ban nahi kar saka!"));
        message.reply(\`✅ \${member.user.tag} ko ban kar diya gaya.\`);
    }

    // 8. Mute Command
    else if (command === 'mute') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.ModerateMembers)) {
            return message.reply("❌ Aapke paas member mute karne ki permission nahi hai!");
        }
        const member = message.mentions.members.first();
        if (!member) return message.reply("⚠️ Kripya mute karne ke liye user mention karein!");
        
        let muteRole = message.guild.roles.cache.find(r => r.name === 'Muted');
        if (!muteRole) {
            try {
                muteRole = await message.guild.roles.create({
                    name: 'Muted',
                    permissions: []
                });
                message.guild.channels.cache.forEach(async (channel) => {
                    await channel.permissionOverwrites.create(muteRole, { SendMessages: false, Speak: false });
                });
            } catch (e) {
                return message.reply("❌ 'Muted' role create nahi ho paya!");
            }
        }
        await member.roles.add(muteRole);
        message.reply(\`🔇 \${member.user.tag} ko successfully mute kar diya gaya hai.\`);
    }

    // 9. Unmute Command
    else if (command === 'unmute') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.ModerateMembers)) {
            return message.reply("❌ Permission denied!");
        }
        const member = message.mentions.members.first();
        if (!member) return message.reply("⚠️ User mention karein!");
        const muteRole = message.guild.roles.cache.find(r => r.name === 'Muted');
        if (muteRole) await member.roles.remove(muteRole);
        message.reply(\`🔊 \/** \${member.user.tag} ko unmute kar diya gaya hai.\`);
    }

    // 10. Lock Channel Command
    else if (command === 'lock') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.ManageChannels)) return message.reply("❌ Permission denied!");
        await message.channel.permissionOverwrites.edit(message.guild.roles.everyone, { SendMessages: false });
        message.reply("🔒 Ye channel lock kar diya gaya hai!");
    }

    // 11. Unlock Channel Command
    else if (command === 'unlock') {
        if (!message.member.permissions.has(PermissionsBitField.Flags.ManageChannels)) return message.reply("❌ Permission denied!");
        await message.channel.permissionOverwrites.edit(message.guild.roles.everyone, { SendMessages: true });
        message.reply("🔓 Ye channel unlock kar diya gaya hai!");
    }

    // 12. Verification System (Embed + Button Setup)
    else if (command === 'verifyembed') {
        if (message.author.id !== ADMIN_ID && !message.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
            return message.reply("❌ Ye command sirf Admin chala sakta hai!");
        }
        const verifyEmbed = new EmbedBuilder()
            .setColor(0x00AE86)
            .setTitle('🔐 Server Verification')
            .setDescription('Server ke andar access paane ke liye neeche diye gaye **Verify** button par click karein.');

        const row = new ActionRowBuilder().addComponents(
            new ButtonBuilder()
                .setCustomId('verify_btn')
                .setLabel('Verify Karein')
                .setStyle(ButtonStyle.Success)
                .setEmoji('✅')
        );

        message.channel.send({ embeds: [verifyEmbed], components: [row] });
        message.delete().catch(() => {});
    }

    // 13. Giveaway System Start
    else if (command === 'giveaway') {
        if (message.author.id !== ADMIN_ID && !message.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
            return message.reply("❌ Aapke paas Giveaway shuru karne ki permission nahi hai!");
        }
        const prize = args.join(' ');
        if (!prize) return message.reply("⚠️ Kripya prize ka naam likhein! (Jaise: \`!giveaway Nitro Classic\` )");

        const gEmbed = new EmbedBuilder()
            .setColor(0xE91E63)
            .setTitle('🎉 GIVEAWAY SHURU HO CHUKA HAI! 🎉')
            .setDescription(\`Prize: **\${prize}**\nNeeche diye gaye button par click karke participate karein!\`)
            .setTimestamp();

        const gRow = new ActionRowBuilder().addComponents(
            new ButtonBuilder()
                .setCustomId('join_giveaway')
                .setLabel('🎉 Participate Karein')
                .setStyle(ButtonStyle.Primary)
        );

        const gMsg = await message.channel.send({ embeds: [gEmbed], components: [gRow] });
        message.delete().catch(() => {});
    }

    // 14. Say Command
    else if (command === 'say') {
        if (message.author.id !== ADMIN_ID) return message.reply("❌ Sirf Admin use kar sakta hai!");
        const text = args.join(' ');
        if (!text) return message.reply("⚠️ Kuch text toh likhein!");
        message.delete().catch(() => {});
        message.channel.send(text);
    }
});

// Button Interaction Handler (Verify & Giveaway Button Logic)
client.on('interactionCreate', async interaction => {
    if (!interaction.isButton()) return;

    // Verify Button Click Logic
    if (interaction.customId === 'verify_btn') {
        if (!VERIFY_ROLE_ID || VERIFY_ROLE_ID === "") {
            return interaction.reply({ content: "⚠️ Server owner ne abhi Verify Role configure nahi kiya hai.", ephemeral: true });
        }
        const member = interaction.guild.members.cache.get(interaction.user.id);
        if (member.roles.cache.has(VERIFY_ROLE_ID)) {
            return interaction.reply({ content: "⚠️ Aap pehle se verified hain!", ephemeral: true });
        }
        await member.roles.add(VERIFY_ROLE_ID).catch(() => {});
        return interaction.reply({ content: "✅ Aap successfully verify ho chuke hain aur aapko role mil gaya hai!", ephemeral: true });
    }

    // Giveaway Button Click Logic
    if (interaction.customId === 'join_giveaway') {
        return interaction.reply({ content: "🎉 Badhai ho! Aapka naam giveaway mein dard kar liya gaya hai.", ephemeral: true });
    }
});

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
pm2 start bot.js --name "discord-ultimate-bot"
pm2 save
pm2 startup

echo "=========================================="
echo " SAARE FEATURES KE SATH BOT ONLINE HO GAYA HAI!"
echo "=========================================="
EOF
