# AWS Lambda Docker Go with Playwright

这个项目展示了如何在AWS Lambda中使用Docker和Go来运行Playwright进行网页抓取。

## 项目结构

```
.
├── Dockerfile          # Docker构建文件
├── docker-compose.yml  # Docker Compose配置
├── main.go            # Lambda函数主代码
├── go.mod             # Go模块定义
└── README.md          # 项目说明
```

## 功能特性

- 使用Go 1.21
- 集成Playwright进行网页抓取
- Docker容器化部署
- AWS Lambda函数实现

## 本地开发

1. 构建Docker镜像：

```bash
docker-compose build
```

2. 运行Lambda函数：

```bash
docker-compose up
```

3. 测试函数（在另一个终端中）：

```bash
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"url":"https://example.com"}'
```

## 部署到AWS Lambda

1. 登录到AWS ECR：

```bash
aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-account.dkr.ecr.your-region.amazonaws.com
```

2. 创建ECR仓库（如果还没有）：

```bash
aws ecr create-repository --repository-name lambda-playwright-go
```

3. 标记并推送镜像：

```bash
docker tag lambda-playwright-go:latest your-account.dkr.ecr.your-region.amazonaws.com/lambda-playwright-go:latest
docker push your-account.dkr.ecr.your-region.amazonaws.com/lambda-playwright-go:latest
```

4. 在AWS Lambda控制台中创建新的函数，选择"Container image"作为部署方式，并选择上传的镜像。

## 注意事项

- Lambda函数超时时间建议设置为至少30秒
- 内存分配建议至少1024MB
- 确保Lambda函数有适当的IAM权限

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
