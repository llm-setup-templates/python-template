"""CLI entry point using Typer."""

import typer

app = typer.Typer(name="my_project", help="my_project CLI")


@app.command()
def run(data: str = typer.Argument(..., help="Input data to process")) -> None:
    """Process data and print result."""
    from my_project.core import process

    result = process(data)
    typer.echo(result)


def main() -> None:
    app()
