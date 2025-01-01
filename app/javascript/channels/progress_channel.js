// app/javascript/channels/progress_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("ProgressChannel", {
  received(data) {
    switch(data.type) {
      case "playlist_info":
        updatePlaylistInfo(data);
        break;
      case "track_progress":
        updateTrackProgress(data);
        break;
      case "complete":
        showDownloadComplete(data);
        break;
      case "error":
        showError(data);
        break;
    }
  }
});

function updatePlaylistInfo(data) {
  document.getElementById('playlist-info').innerHTML = `
    <h2>Downloading Playlist: ${data.name}</h2>
    <p>Total tracks: ${data.total_tracks}</p>
  `;
}

function updateTrackProgress(data) {
  const tracksList = document.getElementById('tracks-list');
  const trackItem = `
    <li style="margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 4px;">
      ${data.index}. ${data.track_name} - ${data.artist_name}
    </li>
  `;
  tracksList.innerHTML += trackItem;
}

function showDownloadComplete(data) {
  document.getElementById('download-complete').innerHTML = `
    <div style="margin-top: 20px; padding: 15px; background: #e8f5e9; border-radius: 4px;">
      <p>Playlist preparation complete!</p>
      <a href="${data.download_path}" class="download-btn" style="display: inline-block; background: #10B981; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; text-decoration: none; margin-top: 10px;">Download Zip File</a>
    </div>
  `;

  const downloadBtn = document.getElementById('download-zip-btn');
  downloadBtn.style.display = 'inline-block';
  downloadBtn.href = data.download_path;

  const allDownloadBtns = document.querySelectorAll('.download-btn, #download-zip-btn');
  allDownloadBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      setTimeout(() => {
        window.location.reload();
      }, 2000);
    });
  });
}

function showError(data) {
  document.getElementById('error-message').innerHTML = `
    <div style="color: red; margin-top: 20px;">
      Error: ${data.message}
    </div>
  `;
}
