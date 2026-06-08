#!/bin/bash

# 待处理：跳过已拉取的 rnacos(e400c7f403c2) 和 redpanda(2c59133cbabe)
declare -A image_groups

image_groups["b63cfcebcc37"]="redis:7.2-alpine
registry.tuf3i.click/library/redis:7.2-alpine"
image_groups["413d57cb67bb"]="registry.tuf3i.click/library/postgres:latest"
image_groups["9d3e8a930cec"]="soldevelo/postgresql-repmgr:17
swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/soldevelo/postgresql-repmgr:17.6.0-debian-12-r0"
image_groups["f7cd6ccdf2bb"]="soldevelo/pgpool:4.6
swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/soldevelo/pgpool:4.6.3-debian-12-r0"
image_groups["ca89cfe76f08"]="registry.tuf3i.click/pgpool/pgpool:latest"

# 原镜像优先
primary=(
    "registry.tuf3i.click/library/redis:7.2-alpine"
    "swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/soldevelo/postgresql-repmgr:17.6.0-debian-12-r0"
    "swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/soldevelo/pgpool:4.6.3-debian-12-r0"
)

for image_id in "${!image_groups[@]}"; do
    mapfile -t tags <<< "${image_groups[$image_id]}"

    pull_tag="${tags[0]}"
    for pt in "${primary[@]}"; do
        for t in "${tags[@]}"; do
            if [[ "$t" == "$pt" ]]; then
                pull_tag="$pt"
                break 2
            fi
        done
    done

    echo "=== Pulling $pull_tag ==="
    if ! docker pull "$pull_tag"; then
        echo "  [FAIL] trying fallback..."
        ok=0
        for t in "${tags[@]}"; do
            [[ "$t" == "$pull_tag" ]] && continue
            echo "  Trying $t ..."
            if docker pull "$t"; then
                pull_tag="$t"
                ok=1
                break
            fi
        done
        if [[ $ok -eq 0 ]]; then
            echo "  [SKIP] all failed"
            continue
        fi
    fi

    for t in "${tags[@]}"; do
        if [[ "$t" != "$pull_tag" ]]; then
            echo "  Tagging: $pull_tag -> $t"
            docker tag "$pull_tag" "$t"
        fi
    done
    echo ""
done

echo "=== Done! ==="
