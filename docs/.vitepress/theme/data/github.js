import fetch from 'node-fetch';

export default {
  async load() {
    try {
      const response = await fetch('https://api.github.com/repos/lg-labs-pentagon/lg5-spring-agent-os/releases/latest');
      if (!response.ok) {
        // Handle non-200 responses
        console.error(`GitHub API responded with ${response.status}`);
        return { latestVersion: 'N/A' };
      }
      const release = await response.json();
      return {
        latestVersion: release.tag_name || 'N/A',
      };
    } catch (error) {
      console.error('Failed to fetch latest release from GitHub:', error);
      return { latestVersion: 'N/A' };
    }
  },
};
