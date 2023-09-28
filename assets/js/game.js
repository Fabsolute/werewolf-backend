import socket from "./game_socket.js";

let channel;
const sendMessageButton = document.getElementById('send-message-button');
const pingButton = document.getElementById('ping-button');
const userList = document.getElementById('user-list');

document.getElementById('join-button').addEventListener('click', () => {
    const username = document.getElementById('username').value;
    const gameName = document.getElementById('game-name').value;

// Now that you are connected, you can join channels with a topic.
// Let's assume you have a channel with a topic named `room` and the
// subtopic is its id - in this case 42:
    channel = socket.channel(`room:${gameName}`, {username})

    channel.on('shout', response => {
        console.log({shout: response});
    });

    channel.on('presence_state', response => {
        for (const j of response.users) {
            const user = document.createElement('li');
            user.setAttribute('data-username', j);
            user.innerText = j;
            userList.appendChild(user);
        }
    });

    channel.on('presence_diff', response => {
        if (response.leaves.length > 0) {
            userList.querySelectorAll(response.leaves.map(l => `[data-username="${l}"]`).join(','))
                .forEach(e => e.remove());
        }

        for (const j of response.joins) {
            if (userList.querySelector(`[data-username="${j}"]`)) {
                continue;
            }

            const user = document.createElement('li');
            user.setAttribute('data-username', j);
            user.innerText = j;
            userList.appendChild(user);
        }
    });

    channel.join()
        .receive("ok", resp => {
            sendMessageButton.removeAttribute('disabled');
            console.log("Joined successfully", resp)
        })
        .receive("error", resp => {
            console.log("Unable to join", resp)
            channel.leave();
        })
});

sendMessageButton.addEventListener('click', () => {
    const message = document.getElementById('message').value;

    channel.push('shout', {message});
});

pingButton.addEventListener('click', () => {
    channel.push('ping', {hello: "mf"})
        .receive('ok', response => {
            console.log({ok: response});
        });
});