# Team Ollama

A private ChatGPT-style website for your team, running on your own big computer.
Employees open a link, log in with their work email, and chat with the models
you already have in Ollama. Nobody needs to install anything or touch a terminal.

The computer handles the queue itself: if more people ask at once than it can
answer, the extra questions wait in line instead of overloading the machine.

---

## What you need before starting

- The big computer, switched on, running Linux, with Ollama already working
- A domain name that is managed by Cloudflare (a free Cloudflare account is fine)
- About 20 minutes, once

---

## Step 1. Get the files onto the computer

Open a terminal on the big computer and paste this:

    git clone https://github.com/kwekkusuma-cloud/team-ollama.git
    cd team-ollama

## Step 2. Create the tunnel in Cloudflare

This is what gives your team a normal web address without exposing the computer
to the internet. All of it is clicking, no typing commands.

1. Go to **one.dash.cloudflare.com** and log in
2. In the left menu click **Networks**, then **Tunnels**
3. Click **Create a tunnel**, choose **Cloudflared**, give it any name such as `team-ai`, click **Next**
4. You will see a box of installation commands. Ignore them. Just find the long
   token inside that text and **copy it**. It is the very long string of random
   letters. Keep it somewhere for the next step.
5. Click **Next**. Now fill in the **Public Hostname** page:
   - **Subdomain**: `ai`
   - **Domain**: pick your domain
   - **Type**: `HTTP`
   - **URL**: `localhost:3000`
6. Click **Save tunnel**

Your team's address is now `ai.yourdomain.com`.

## Step 3. Turn it on

Back in the terminal on the big computer:

    ./setup.sh

It will ask you to paste the token from step 2. Paste it and press Enter.
When it says **Done**, the website is live.

## Step 4. Lock it to your employees only

Right now anyone who finds the link could sign up. This step fixes that.

1. Go back to **one.dash.cloudflare.com**
2. Left menu, click **Access**, then **Applications**, then **Add an application**
3. Choose **Self-hosted**
4. Give it a name such as `Team AI`, and set the domain to `ai.yourdomain.com`
5. Click **Next** to reach the policy page:
   - Policy name: `Staff`
   - Action: **Allow**
   - Include: choose **Emails** and type in each employee's work email address
6. Click **Next**, then **Add application**

Now visiting the link asks for an email, sends a 6-digit code to it, and only
lets in the addresses you listed.

## Step 5. Make your own account first

Open `ai.yourdomain.com` yourself and sign up. **The first account created is
the admin account**, so do this before telling anyone else about the link.

Then send everyone the link. They sign up the same way, and you approve each new
person from the admin panel inside the site (top right, Admin Panel, Users).

---

## Everyday things

**Add a new model for the team**

    ollama pull llama3.3

It appears in the model dropdown on the website within a minute.

**Add or remove an employee**
Cloudflare dashboard, Access, Applications, your app, edit the Staff policy,
add or delete their email. Removing an email locks them out immediately.

**Let more people chat at the same time**
The default is 4 at once. To raise it:

    OLLAMA_NUM_PARALLEL=8 ./setup.sh

More parallel means more memory used. With 200 GB you have plenty of room, so
raise it if replies feel like they are waiting rather than typing slowly.

**Stop everything**

    docker compose down

**Start it again**

    docker compose up -d

**Something is broken, what happened?**

    docker compose logs open-webui

---

## What this is made of

- **Open WebUI** is the website itself: accounts, chat history, model picker, file uploads
- **Cloudflare Tunnel** carries traffic to your computer without opening any ports on your network
- **Cloudflare Access** is the email login wall in front of it
- **Ollama** is what you already had, doing the actual thinking

The website is only reachable through Cloudflare. It is not published on your
local network or the open internet.
