export default {
  async load() {
    try {
      const response = await fetch('https://api.github.com/repos/lg-labs-pentagon/lg5-spring-agent-os/releases/latest');
      if (!response.ok) {
        if (response.status === 404) {
          return { latestVersion: 'No releases yet' };
        }
        return { latestVersion: 'Error fetching version' };
      }
      const release = await response.json();
      return {
        latestVersion: release.tag_name || 'N/A',
      };
    } catch (error) {
      return { latestVersion: 'Error fetching version' };
    }
  },
};
