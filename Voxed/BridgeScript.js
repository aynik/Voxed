const containerSelector = ".group.bg-gray-50";
const contentSelector = ".whitespace-pre-wrap";
const replayButtonSelector = ".replayButton";
const stopSymbol = "■";
const recordSymbol = "●";
const replaySymbol = "⏵";

let textMonitorInterval;
let prevInnerText = "";
let sentenceBuffer = "";
let activeSelectionStart = null;
let activeSelectionEnd = null;

function getTextarea() {
  return document.querySelector("textarea");
}

function getSubmitButton() {
  return getTextarea().nextElementSibling;
}

function getRecordButton() {
  return document.getElementById("recordButton");
}

function getRegenerateButton() {
  return getSubmitButton().parentElement.parentElement.querySelector(
    ".btn-neutral"
  );
}

function createReplayButtons() {
  Array.from(document.querySelectorAll(containerSelector)).forEach(
    (element) => {
      if (!element.querySelector(contentSelector)) return;
      const buttonContainer = element.firstChild;
      if (!buttonContainer.querySelector(replayButtonSelector)) {
        const replayButton = document.createElement("button");
        replayButton.textContent = replaySymbol;
        replayButton.classList.add("bg-gray-100", "text-black", "replayButton");
        replayButton.style.height = "30px";
        replayButton.style.width = "30px";
        replayButton.style.textAlign = "center";
        replayButton.style.borderRadius = "2px";
        replayButton.addEventListener("click", () => {
          const result = element.querySelector(contentSelector);
          window.webkit.messageHandlers.startSpeaking.postMessage(
            result.innerText.replace(/\u200B\d+/g, "").replace(/\u200B/g, "")
          );
        });
        const avatarElement = buttonContainer.firstChild;
        buttonContainer.insertBefore(replayButton, avatarElement);
        buttonContainer.removeChild(avatarElement);
      }
    }
  );
}

function enableReplayButtons() {
  Array.from(document.querySelectorAll(replayButtonSelector)).forEach(
    (element) => {
      element.style.opacity = 1;
      element.disabled = false;
    }
  );
}

function disableReplayButtons() {
  Array.from(document.querySelectorAll(replayButtonSelector)).forEach(
    (element) => {
      element.style.opacity = 0.1;
      element.disabled = true;
    }
  );
}

function createRecordButton() {
  const recordButton = document.createElement("button");
  recordButton.setAttribute("id", "recordButton");
  recordButton.textContent = recordSymbol;
  recordButton.classList.add("bg-white", "dark:bg-gray-800", "text-red-600");
  recordButton.style.height = "40px";
  recordButton.style.padding = "0 12px";
  recordButton.style.borderRadius = "6px";
  recordButton.style.margin = "1px 8px 0 0";
  recordButton.addEventListener("click", startRecording);
  getTextarea().parentNode.parentNode.prepend(recordButton);
}

function processText(newText) {
  let textToProcess = newText;
  const regex = /[:.!?]+/;

  while (textToProcess.length > 0) {
    const match = regex.exec(textToProcess);

    if (match) {
      const chunk = textToProcess.slice(0, match.index + match[0].length);
      textToProcess = textToProcess.slice(match.index + match[0].length);
      sentenceBuffer += chunk;
      window.webkit.messageHandlers.startSpeaking.postMessage(
        sentenceBuffer.trim()
      );
      sentenceBuffer = "";
    } else {
      sentenceBuffer += textToProcess;
      textToProcess = "";
    }
  }
}

function startMonitoringText() {
  if (textMonitorInterval) clearInterval(textMonitorInterval);
  textMonitorInterval = setInterval(() => {
    const container = Array.from(
      document.querySelectorAll(containerSelector)
    ).pop();
    const result = container.querySelector(contentSelector);
    const currentInnerText = result
      ? result.innerText
          .replace(/\u200B\d+/g, "")
          .replace(/\u200B/g, "")
          .slice(0, -20)
      : "";
    if (!currentInnerText.length) return;
    const newText = currentInnerText.replace(prevInnerText, "");

    if (newText.length > 0) {
      prevInnerText = currentInnerText;
      processText(newText);
    } else {
      clearInterval(textMonitorInterval);
      window.webkit.messageHandlers.startSpeaking.postMessage(
        sentenceBuffer.trim() + result.innerText.slice(-20)
      );
      sentenceBuffer = prevInnerText = "";
    }
  }, 3000);
}

function startRecording(event) {
  if (event) {
    event.preventDefault();
    event.stopPropagation();
  }
  window.webkit.messageHandlers.startRecording.postMessage("");
}

window.showStopButton = function () {
  getRecordButton().textContent = stopSymbol;
  getRecordButton().classList.remove(
    "bg-white",
    "dark:bg-gray-800",
    "text-red-600"
  );
  getRecordButton().classList.add(
    "bg-red-500",
    "dark:bg-red-500",
    "text-white"
  );
  getRecordButton().removeEventListener("click", startRecording);
  getRecordButton().addEventListener("click", stopRecordingOrSpeaking);
  disableReplayButtons();
};

function stopRecordingOrSpeaking(event) {
  if (event) {
    event.preventDefault();
    event.stopPropagation();
  }
  if (textMonitorInterval) clearInterval(textMonitorInterval);
  window.webkit.messageHandlers.stopRecordingOrSpeaking.postMessage("");
  sentenceBuffer = prevInnerText = "";
}

window.showRecordButton = function () {
  getRecordButton().textContent = recordSymbol;
  getRecordButton().classList.remove("bg-red-500", "text-white");
  getRecordButton().classList.add(
    "bg-white",
    "dark:bg-gray-800",
    "text-red-600"
  );
  getRecordButton().removeEventListener("click", stopRecordingOrSpeaking);
  getRecordButton().addEventListener("click", startRecording);
  enableReplayButtons();
};

function replaceTextInSelection(textarea, text) {
  if (activeSelectionStart === null || activeSelectionEnd === null) {
    activeSelectionStart = textarea.selectionStart;
    activeSelectionEnd = textarea.selectionEnd;
  }
  textarea.value =
    textarea.value.substring(0, activeSelectionStart) +
    text +
    textarea.value.substring(activeSelectionEnd);
  textarea.selectionStart = activeSelectionStart;
  textarea.selectionEnd = activeSelectionStart + text.length;
  activeSelectionEnd = textarea.selectionEnd;
  textarea.style.height = "auto";
  textarea.style.height = textarea.scrollHeight + "px";
}

window.setTextFromApp = function (text) {
  replaceTextInSelection(getTextarea(), text);
  getSubmitButton().disabled = false;
};

setInterval(() => {
  createReplayButtons();
  if (!getRecordButton() && getTextarea()) {
    createRecordButton();
  }
  if (getSubmitButton()) {
    getSubmitButton().onclick = function () {
      window.webkit.messageHandlers.stopRecording.postMessage("");
      setTimeout(startMonitoringText, 2000);
    };
  }
  if (getRegenerateButton()) {
    getRegenerateButton().onclick = function () {
      if (this.querySelector("polyline")) {
        window.webkit.messageHandlers.stopRecording.postMessage("");
        setTimeout(startMonitoringText, 2000);
      }
    };
  }
}, 500);
