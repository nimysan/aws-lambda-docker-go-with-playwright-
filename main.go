package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/playwright-community/playwright-go"
)

type Event struct {
	URL string `json:"url"`
}

type Response struct {
	Title   string `json:"title"`
	Content string `json:"content"`
	Error   string `json:"error,omitempty"`
}

func HandleRequest(ctx context.Context, event Event) (Response, error) {
	if event.URL == "" {
		return Response{Error: "URL is required"}, nil
	}

	pw, err := playwright.Run()
	if err != nil {
		return Response{Error: fmt.Sprintf("could not start playwright: %v", err)}, nil
	}
	defer pw.Stop()

	browser, err := pw.Chromium.Launch(playwright.BrowserTypeLaunchOptions{
		Headless: playwright.Bool(true),
	})
	if err != nil {
		return Response{Error: fmt.Sprintf("could not launch browser: %v", err)}, nil
	}
	defer browser.Close()

	page, err := browser.NewPage()
	if err != nil {
		return Response{Error: fmt.Sprintf("could not create page: %v", err)}, nil
	}
	defer page.Close()

	if _, err = page.Goto(event.URL); err != nil {
		return Response{Error: fmt.Sprintf("could not goto: %v", err)}, nil
	}

	title, err := page.Title()
	if err != nil {
		return Response{Error: fmt.Sprintf("could not get title: %v", err)}, nil
	}

	content, err := page.TextContent("body")
	if err != nil {
		return Response{Error: fmt.Sprintf("could not get content: %v", err)}, nil
	}

	return Response{
		Title:   title,
		Content: content,
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
