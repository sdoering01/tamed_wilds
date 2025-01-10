const SCROLL_INFO_KEY = "scrollInfo";

export function initScrollRestoration() {
    restoreScroll();

    // TODO: Add scroll restoration to forms
    window.addEventListener("phoenix.link.click", function(e) {
        // We only want to save the scroll position when a non-GET request is sent, since GET requests are for navigation
        const isNonGetRequest = (e.target.dataset.method || "get").toLowerCase() !== "get";
        const isScrolled = window.scrollX !== 0 || window.scrollY !== 0;
        if (isNonGetRequest && isScrolled) {
            const scrollInfo = {
                scrollX: window.scrollX,
                scrollY: window.scrollY,
                // We only need to restore the scroll position if the user naviagted to the same page
                path: window.location.pathname,
                // Makes us able to circumvent odd behvaior when the POST request was sent but the response was not received
                timestamp: new Date().toISOString(),
            };
            sessionStorage.setItem(SCROLL_INFO_KEY, JSON.stringify(scrollInfo));
        }
    });
};

function restoreScroll() {
    const scrollInfo = sessionStorage.getItem(SCROLL_INFO_KEY);
    if (scrollInfo) {
        sessionStorage.removeItem(SCROLL_INFO_KEY);
        try {
            const info = JSON.parse(scrollInfo);
            const previousTime = new Date(info.timestamp);
            const maxDiff = 10 * 1000;
            if (Date.now() - previousTime.getTime() < maxDiff && info.path === window.location.pathname) {
                window.scrollTo(info.scrollX, info.scrollY);
            }
        } catch (e) {
            console.error("Error restoring scroll position", e);
        }
    }
}
