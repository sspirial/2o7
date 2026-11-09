let installPrompt = null;
const installButton = document.getElementById("install");

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch((error) => {
    console.error("Service worker registration failed", error);
  });
}

if (installButton) {
  installButton.hidden = true;
  addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    installPrompt = event;
    installButton.hidden = false;
  });

  installButton.addEventListener("click", async () => {
    if (!installPrompt) return;
    installPrompt.prompt();
    const choice = await installPrompt.userChoice;
    if (choice.outcome === "accepted") installButton.hidden = true;
    installPrompt = null;
  });

  addEventListener("appinstalled", () => {
    installPrompt = null;
    installButton.hidden = true;
  });
}
