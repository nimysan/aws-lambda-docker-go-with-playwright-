# AWS Lambda Docker Go with Playwright

这个项目展示了如何在AWS Lambda中使用Docker和Go来运行Playwright进行网页抓取。项目使用AWS Lambda容器镜像支持，基于AWS提供的基础镜像构建。

## 项目结构

```
.
├── Dockerfile          # Docker构建文件，基于AWS Lambda基础镜像
├── docker-compose.yml  # 本地测试配置
├── main.go            # Lambda函数主代码
├── go.mod             # Go模块定义
└── README.md          # 项目说明
```

## 功能特性

- 使用Go 1.21
- 集成Playwright进行网页抓取
- AWS Lambda容器镜像部署
- 完整的浏览器环境支持

## 本地测试

1. 构建Docker镜像：

```bash
docker compose build
```

2. 启动本地Lambda测试环境：

```bash
docker compose up
```

3. 在另一个终端中测试函数：

```bash
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"url":"https://example.com"}'
```

## AWS Lambda部署

### 1. 准备ECR仓库

```bash
# 设置环境变量
export AWS_REGION=your-region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REPOSITORY=lambda-playwright-go

# 创建ECR仓库
aws ecr create-repository \
    --repository-name ${ECR_REPOSITORY} \
    --image-scanning-configuration scanOnPush=true
```

### 2. 构建和推送镜像

```bash
# 登录到ECR
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# 构建镜像
docker build -t ${ECR_REPOSITORY} .

# 标记镜像
docker tag ${ECR_REPOSITORY}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

# 推送镜像到ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest
```

### 3. 创建Lambda函数

可以通过AWS CLI创建Lambda函数：

```bash
aws lambda create-function \
    --function-name playwright-scraper \
    --package-type Image \
    --code ImageUri=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest \
    --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-role \
    --timeout 30 \
    --memory-size 1024
```

或者通过AWS控制台：

1. 打开Lambda控制台
2. 点击"创建函数"
3. 选择"Container image"
4. 选择上传的ECR镜像
5. 配置以下设置：
   - 内存：至少1024 MB
   - 超时：至少30秒
   - 执行角色：具有基本Lambda执行权限的角色

## Lambda函数配置

### 内存和超时设置

- 内存：建议至少1024MB
- 超时：建议至少30秒
- 临时存储：建议至少512MB

### 环境变量

```
PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
```

## 输入格式

函数接受JSON格式的输入：

```json
{
    "url": "https://example.com"
}
```

## 输出格式

函数返回JSON格式的输出：

```json
{
    "title": "页面标题",
    "content": "页面内容",
    "error": "如果有错误会显示在这里"
}
```

## 注意事项

1. 确保Lambda函数有足够的内存和执行时间
2. 第一次调用可能会较慢（冷启动）
3. 建议使用预置并发来减少冷启动时间
4. 确保目标网站允许爬虫访问
5. 考虑设置适当的超时处理
6. 注意AWS Lambda的并发限制

## 故障排除

1. 如果遇到内存不足错误，增加Lambda函数的内存配置
2. 如果遇到超时错误，增加超时设置
3. 如果遇到权限错误，检查IAM角色配置
4. 如果浏览器启动失败，检查环境变量设置
