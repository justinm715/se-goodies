const os = require('os');
const path = require('path');
const chokidar = require('chokidar');
const fs = require('fs');
const { ipcRenderer } = require('electron');

// ==========

const counterTextElem = document.getElementById('counterText');

let counter = 0;

ipcRenderer.on('incrementCounter', () => {
    counter += 1;
    counterTextElem.textContent = 'Counter: ' + counter;
});


// ==========

const desktopPath = path.join(os.homedir(), 'OneDrive', 'Desktop');
const fileListElem = document.getElementById('fileList');

function getFileDetails(filePath) {
    const stats = fs.statSync(filePath);
    return {
        size: stats.size,
        modifiedDate: stats.mtime
    };
}

function getDesktopFiles() {
    const watched = watcher.getWatched();
    const files = watched[desktopPath] || [];
    return files.map(file => {
        const details = getFileDetails(path.join(desktopPath, file));
        return {
            name: file,
            ...details
        };
    }).sort((a, b) => a.name.localeCompare(b.name)); // Alphabetically sort by filename
}

function updateFileList() {
    const files = getDesktopFiles();

    fileListElem.innerHTML = `
        <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
                <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size (Bytes)</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Modified Date</th>
                </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
            </tbody>
        </table>
    `;

    const tbody = fileListElem.querySelector('tbody');

    files.forEach(file => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td class="px-6 py-4 whitespace-nowrap">${file.name}</td>
            <td class="px-6 py-4 whitespace-nowrap">${file.size}</td>
            <td class="px-6 py-4 whitespace-nowrap">${file.modifiedDate.toLocaleString()}</td>
        `;
        tbody.appendChild(row);
    });
}

const watcher = chokidar.watch(desktopPath, {
    ignored: /[\/\\]\./, // ignore dotfiles
    persistent: true,
});

watcher
    .on('add', path => updateFileList())
    .on('unlink', path => updateFileList())
    .on('change', path => updateFileList());  // Respond to 'change' events

// Initial load
updateFileList();
