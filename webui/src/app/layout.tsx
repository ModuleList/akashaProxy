import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Typography from '@mui/material/Typography';

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "akashaProxy WebUI",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Typography variant="h5" style={{marginBottom: '1em'}}>
          akashaProxy
        </Typography>
        {children}
      </body>
    </html>
  );
}
