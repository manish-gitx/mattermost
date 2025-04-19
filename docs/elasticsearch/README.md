# Scalable Enterprise Search with Elasticsearch/OpenSearch

This guide will help you set up Elasticsearch or OpenSearch for Mattermost, enabling scalable search capabilities that can handle millions of messages.

## Overview

Mattermost's default SQL-based search is suitable for smaller deployments but experiences performance degradation as message volume grows. By integrating with Elasticsearch or OpenSearch, you can:

- Achieve significantly faster search performance
- Scale effectively to handle millions of messages
- Support advanced search capabilities
- Reduce database load during search operations

## Prerequisites

- Mattermost Server (v7.0 or later)
- Elasticsearch (v7.x or v8.x) or OpenSearch (v1.x or v2.x)
- Sufficient system resources to run both Mattermost and Elasticsearch/OpenSearch

## System Requirements

Elasticsearch/OpenSearch system requirements depend on your message volume:

| Messages      | RAM          | Storage     | CPU     |
|---------------|--------------|-------------|---------|
| < 5 million   | 8GB min      | 50GB+       | 4 cores |
| 5-10 million  | 16GB min     | 100GB+      | 4-8 cores |
| > 10 million  | 32GB+ min    | 200GB+      | 8+ cores |

## 1. Install Elasticsearch or OpenSearch

### Elasticsearch Installation

```bash
# Example for Ubuntu/Debian
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update && sudo apt-get install elasticsearch
```

### OpenSearch Installation

```bash
# Example for Ubuntu/Debian
wget -qO - https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo apt-key add -
echo "deb https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list
sudo apt-get update && sudo apt-get install opensearch
```

## 2. Configure Elasticsearch/OpenSearch

Edit the configuration file:

### Elasticsearch Configuration

```yaml
# /etc/elasticsearch/elasticsearch.yml
cluster.name: mattermost
node.name: mattermost-es-01
network.host: 0.0.0.0
discovery.type: single-node
xpack.security.enabled: false
```

### OpenSearch Configuration

```yaml
# /etc/opensearch/opensearch.yml
cluster.name: mattermost
node.name: mattermost-os-01
network.host: 0.0.0.0
discovery.type: single-node
plugins.security.disabled: true
```

## 3. Start Elasticsearch/OpenSearch

```bash
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
# or for OpenSearch
sudo systemctl enable opensearch
sudo systemctl start opensearch
```

## 4. Configure Mattermost

1. Go to **System Console > Environment > Elasticsearch**
2. Set the following configurations:

   - **Enable Elasticsearch Indexing**: `true`
   - **Server Connection Address**: `http://localhost:9200` (or your Elasticsearch/OpenSearch server address)
   - **Backend**: Select `elasticsearch` or `opensearch`
   - **Username**: (optional, if using authentication)
   - **Password**: (optional, if using authentication)
   - **Enable Elasticsearch for search queries**: `true`
   - **Enable Elasticsearch for autocomplete queries**: `true`

3. Click **Save** and then **Test Connection** to verify the setup

## 5. Build Indexes

After configuring Elasticsearch/OpenSearch, you need to build your initial indexes:

1. Go to **System Console > Environment > Elasticsearch**
2. Click **Purge Indexes** (to ensure a clean start)
3. Click **Build Indexes** to index all existing posts

## 6. Advanced Configuration

### Index Settings

For larger deployments, you may want to adjust index settings:

- **Number of Shards**: Increase for larger datasets (default: 1)
- **Number of Replicas**: Increase for better availability (default: 1)

### Bulk Indexing

For initial indexing of large message volumes, consider:

- **Bulk Indexing Batch Size**: Adjust based on your server's RAM (default: 10000)

## 7. Performance Tuning

### JVM Heap Size

Edit `/etc/elasticsearch/jvm.options` or `/etc/opensearch/jvm.options`:

```
-Xms4g
-Xmx4g
```

Allocate 50% of available RAM, but not more than 32GB due to JVM limitations.

### System Configuration

```bash
# Set vm.max_map_count
sudo sysctl -w vm.max_map_count=262144
# Make it permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

## 8. Monitoring

Monitor your search engine's health and performance:

```bash
# Elasticsearch
curl -X GET "localhost:9200/_cluster/health?pretty"

# OpenSearch
curl -X GET "localhost:9200/_cluster/health?pretty"
```

## Troubleshooting

### Common Issues

1. **Connection Issues**:
   - Verify Elasticsearch/OpenSearch is running: `systemctl status elasticsearch`
   - Check network connectivity: `curl http://localhost:9200`

2. **Indexing Failures**:
   - Check Mattermost logs for details
   - Verify disk space availability
   - Check JVM heap settings

3. **Slow Searches**:
   - Review index configuration
   - Check system resources (CPU, memory, disk I/O)
   - Consider adding more nodes in a cluster setup

## Multi-Node Deployment

For production environments with high message volumes, consider a multi-node cluster:

1. Configure multiple Elasticsearch/OpenSearch nodes
2. Set `discovery.seed_hosts` in configuration
3. Adjust number of shards and replicas for optimal performance
4. Use a load balancer for client connections

## Conclusion

By following this guide, you'll have a scalable search solution for Mattermost that can handle millions of messages with excellent performance. Properly tuned Elasticsearch or OpenSearch can significantly improve the user experience for large deployments. 